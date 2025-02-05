package com.example.ustock_app;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.PorterDuff;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

public class MainActivity extends AppCompatActivity {

    private LinearLayout listsContainer;
    private ArrayList<String> userLists;
    private SharedPreferences sharedPreferences;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        listsContainer = findViewById(R.id.listsContainer);
        sharedPreferences = getSharedPreferences("USTOCK_PREFS", Context.MODE_PRIVATE);
        userLists = new ArrayList<>(sharedPreferences.getStringSet("userLists", new HashSet<>()))
        ;

        for (String list : userLists) {
            addListToUI(list);
        }

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
            if (!listName.isEmpty()) {
                addListToUI(listName);
                userLists.add(listName);
                saveLists();
            }
        });
        builder.setNegativeButton("Annuler", (dialog, which) -> dialog.cancel());
        builder.show();
    }

    private void addListToUI(String listName) {
        TextView listView = new TextView(this);
        listView.setText(listName);
        listView.setTextSize(18);
        listView.setPadding(16, 16, 16, 16);
        listView.setBackground(getResources().getDrawable(R.drawable.rounded_corner));
        listView.setOnClickListener(v -> openListActivity(listName));

        listView.setOnLongClickListener(v -> {
            showDeleteConfirmationDialog(listName, listView);
            return true;
        });

        listsContainer.addView(listView);
    }

    private void openListActivity(String listName) {
        Intent intent = new Intent(this, ListDetailActivity.class);
        intent.putExtra("list_name", listName);
        startActivity(intent);
    }

    private void showDeleteConfirmationDialog(String listName, View listView) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Supprimer la liste");
        builder.setMessage("Voulez-vous vraiment supprimer cette liste ?");
        builder.setPositiveButton("Supprimer", (dialog, which) -> {
            userLists.remove(listName);
            listsContainer.removeView(listView);
            removeListData(listName);
            saveLists();
        });
        builder.setNegativeButton("Annuler", (dialog, which) -> dialog.dismiss());
        builder.show();
    }

    private void removeListData(String listName) {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.remove(listName);
        editor.apply();
    }

    private void saveLists() {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        Set<String> set = new HashSet<>(userLists);
        editor.putStringSet("userLists", set);
        editor.apply();
    }
}