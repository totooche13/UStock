package com.example.ustock_app;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import com.journeyapps.barcodescanner.ScanContract;
import com.journeyapps.barcodescanner.ScanOptions;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

public class BarcodeScannerActivity extends AppCompatActivity {

    private ArrayList<String> userLists;
    private SharedPreferences sharedPreferences;

    private final ActivityResultLauncher<ScanOptions> barcodeLauncher = registerForActivityResult(
            new ScanContract(),
            result -> {
                if (result.getContents() != null) {
                    Toast.makeText(BarcodeScannerActivity.this, "Code Scanné: " + result.getContents(), Toast.LENGTH_LONG).show();
                    showAddToListDialog(result.getContents());
                } else {
                    Toast.makeText(BarcodeScannerActivity.this, "Aucun code scanné", Toast.LENGTH_SHORT).show();
                    Intent intent = new Intent(BarcodeScannerActivity.this, MainActivity.class);
                    startActivity(intent);
                    finish(); // Ferme BarcodeScannerActivity
                }
            }
    );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        sharedPreferences = getSharedPreferences("USTOCK_PREFS", Context.MODE_PRIVATE);
        userLists = new ArrayList<>(sharedPreferences.getStringSet("userLists", new HashSet<>()))
        ;
        ScanOptions options = new ScanOptions();
        options.setPrompt("Placez le code-barres devant la caméra");
        options.setBeepEnabled(true);
        options.setOrientationLocked(true);
        options.setCaptureActivity(PortraitCaptureActivity.class);
        barcodeLauncher.launch(options);
    }

    private void showAddToListDialog(String scannedCode) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Ajouter l'article à une liste");
        ListView listView = new ListView(this);
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, userLists);
        listView.setAdapter(adapter);
        listView.setOnItemClickListener((parent, view, position, id) -> {
            String selectedList = userLists.get(position);
            saveItemToList(selectedList, scannedCode);
            Toast.makeText(this, "Article ajouté à " + selectedList, Toast.LENGTH_SHORT).show();
            Intent intent = new Intent(BarcodeScannerActivity.this, MainActivity.class);
            startActivity(intent);
            finish();
        });
        builder.setView(listView);
        builder.setNegativeButton("Annuler", (dialog, which) -> dialog.cancel());
        builder.show();
    }

    private void saveItemToList(String listName, String item) {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        Set<String> items = new HashSet<>(sharedPreferences.getStringSet(listName, new HashSet<>()));
        items.add(item);
        editor.putStringSet(listName, items);
        editor.apply();
    }
}