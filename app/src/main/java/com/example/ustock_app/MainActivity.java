package com.example.ustock_app;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.PorterDuff;
import android.os.Bundle;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ListView;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

public class MainActivity extends AppCompatActivity {

    private ListView listsContainer;
    private ArrayList<String> userLists;
    private ArrayAdapter<String> adapter;
    private SharedPreferences sharedPreferences;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        listsContainer = findViewById(R.id.listsContainer);
        sharedPreferences = getSharedPreferences("USTOCK_PREFS", Context.MODE_PRIVATE);
        userLists = new ArrayList<>(sharedPreferences.getStringSet("userLists", new HashSet<>()));

        adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, userLists);
        listsContainer.setAdapter(adapter);

        listsContainer.setOnItemClickListener((parent, view, position, id) -> openListActivity(userLists.get(position)));
        listsContainer.setOnItemLongClickListener((parent, view, position, id) -> {
            showDeleteConfirmationDialog(userLists.get(position));
            return true;
        });

        Button barcode_button = findViewById(R.id.addArticleButton);
        Button addListButton = findViewById(R.id.addListButton);
        ImageView shopList = findViewById(R.id.shopListPageButton);


        addListButton.setOnClickListener(v -> showAddListDialog());
        barcode_button.setOnClickListener(view -> {
            Intent intent = new Intent(MainActivity.this, BarcodeScannerActivity.class);
            intent.putStringArrayListExtra("userLists", userLists);
            startActivity(intent);
        });

        shopList.setOnClickListener(view -> {
            Intent intent = new Intent(MainActivity.this, ShopList.class);
            startActivity(intent);
        });

        ImageView currentActivityIcon = findViewById(R.id.myProductPage); // ID de l'image
        currentActivityIcon.setColorFilter(getResources().getColor(R.color.selected_color), PorterDuff.Mode.SRC_IN);

    }

    private void showAddListDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Nouvelle liste");
        final EditText input = new EditText(this);
        builder.setView(input);
        builder.setPositiveButton("Ajouter", (dialog, which) -> {
            String listName = input.getText().toString().trim();
            if (!listName.isEmpty() && !userLists.contains(listName)) {
                userLists.add(listName);
                saveLists();
                adapter.notifyDataSetChanged();
            }
        });
        builder.setNegativeButton("Annuler", (dialog, which) -> dialog.cancel());
        builder.show();
    }

    private void openListActivity(String listName) {
        Intent intent = new Intent(this, ListDetailActivity.class);
        intent.putExtra("list_name", listName);
        startActivity(intent);
    }

    private void showDeleteConfirmationDialog(String listName) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Supprimer la liste");
        builder.setMessage("Voulez-vous vraiment supprimer cette liste ?");
        builder.setPositiveButton("Supprimer", (dialog, which) -> {
            userLists.remove(listName);
            saveLists();
            adapter.notifyDataSetChanged();
        });
        builder.setNegativeButton("Annuler", (dialog, which) -> dialog.dismiss());
        builder.show();
    }

    private void saveLists() {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        Set<String> set = new HashSet<>(userLists);
        editor.putStringSet("userLists", set);
        editor.apply();
    }
}