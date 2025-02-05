package com.example.ustock_app;

import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import java.util.ArrayList;

public class MainActivity extends AppCompatActivity {

    private LinearLayout listsContainer;
    private ArrayList<String> userLists;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        listsContainer = findViewById(R.id.listsContainer);
        userLists = new ArrayList<>();
        Button barcode_button = findViewById(R.id.barcode_button);

        Button addListButton = findViewById(R.id.monButton);
        addListButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showAddListDialog();
            }
        });

        barcode_button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MainActivity.this, BarcodeScannerActivity.class);
                startActivity(intent);
            }
        });
    }

    private void showAddListDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Nouvelle liste");

        final EditText input = new EditText(this);
        builder.setView(input);

        builder.setPositiveButton("Ajouter", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                String listName = input.getText().toString().trim();
                if (!listName.isEmpty()) {
                    addListToUI(listName);
                    userLists.add(listName);
                }
            }
        });
        builder.setNegativeButton("Annuler", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        builder.show();
    }

    private void addListToUI(String listName) {
        TextView listView = new TextView(this);
        listView.setText(listName);
        listView.setTextSize(18);
        listView.setPadding(16, 16, 16, 16);
        listView.setBackground(getResources().getDrawable(R.drawable.rounded_corner));
        listView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openListActivity(listName);
            }
        });
        listsContainer.addView(listView);
    }

    private void openListActivity(String listName) {
        Intent intent = new Intent(this, ListDetailActivity.class);
        intent.putExtra("list_name", listName);
        startActivity(intent);
    }
}