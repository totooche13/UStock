package com.example.ustock_app;

import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

public class ListDetailActivity extends AppCompatActivity {

    private ListView itemListView;
    private ArrayList<String> itemList;
    private ArrayAdapter<String> itemAdapter;
    private SharedPreferences sharedPreferences;
    private String listName;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list_detail);

        TextView listTitle = findViewById(R.id.listTitle);
        itemListView = findViewById(R.id.itemListView);

        listName = getIntent().getStringExtra("list_name");
        listTitle.setText(listName);

        sharedPreferences = getSharedPreferences("USTOCK_PREFS", Context.MODE_PRIVATE);
        Set<String> items = sharedPreferences.getStringSet(listName, new HashSet<>());

        itemList = new ArrayList<>(items);
        itemAdapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, itemList);
        itemListView.setAdapter(itemAdapter);

        itemListView.setOnItemLongClickListener((parent, view, position, id) -> {
            showDeleteItemDialog(position);
            return true;
        });

        Button homeButton = findViewById(R.id.homeButton);
        homeButton.setOnClickListener(view -> {
            Intent intent = new Intent(ListDetailActivity.this, MainActivity.class);
            startActivity(intent);
        });
    }

    private void showDeleteItemDialog(int position) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Supprimer l'article");
        builder.setMessage("Voulez-vous vraiment supprimer cet article ?");
        builder.setPositiveButton("Supprimer", (dialog, which) -> {
            String itemToRemove = itemList.get(position);
            itemList.remove(position);
            itemAdapter.notifyDataSetChanged();
            removeItemFromSharedPreferences(itemToRemove);
        });
        builder.setNegativeButton("Annuler", (dialog, which) -> dialog.dismiss());
        builder.show();
    }

    private void removeItemFromSharedPreferences(String item) {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        Set<String> updatedItems = new HashSet<>(sharedPreferences.getStringSet(listName, new HashSet<>()));
        updatedItems.remove(item);
        editor.putStringSet(listName, updatedItems);
        editor.apply();
    }
}