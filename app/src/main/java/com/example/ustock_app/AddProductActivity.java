package com.example.ustock_app;

import android.annotation.SuppressLint;
import android.app.DatePickerDialog;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import android.os.AsyncTask;
import org.json.JSONException;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class AddProductActivity extends AppCompatActivity {

    private ImageView productImage;
    private TextView productName, productQuantity;
    private Spinner listSelector;
    private Switch expirationSwitch;
    private Button addProductButton, increaseQuantity, decreaseQuantity, selectExpirationDate;
    private SharedPreferences sharedPreferences;
    private ArrayList<String> userLists;
    private String scannedCode;
    private Calendar calendar;
    private int quantity = 1; // Quantité par défaut
    private String expirationDate = ""; // Stocke la date sélectionnée

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_product);

        productImage = findViewById(R.id.productImage);
        productName = findViewById(R.id.productName);
        productQuantity = findViewById(R.id.productQuantity);
        listSelector = findViewById(R.id.listSelector);
        expirationSwitch = findViewById(R.id.expirationSwitch);
        addProductButton = findViewById(R.id.addProductButton);
        increaseQuantity = findViewById(R.id.increaseQuantity);
        decreaseQuantity = findViewById(R.id.decreaseQuantity);
        selectExpirationDate = findViewById(R.id.selectExpirationDate);
        Button cancelProductButton = findViewById(R.id.cancelProductButton);

        sharedPreferences = getSharedPreferences("USTOCK_PREFS", Context.MODE_PRIVATE);
        userLists = new ArrayList<>(sharedPreferences.getStringSet("userLists", new HashSet<>()));

        scannedCode = getIntent().getStringExtra("scanned_code");

        // Charger les listes dans le Spinner
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, R.layout.spinner_item, userLists);
        adapter.setDropDownViewResource(R.layout.spinner_item);
        listSelector.setAdapter(adapter);

        // Initialisation du calendrier pour DatePicker
        calendar = Calendar.getInstance();
        updateDateButton();

        // Activer le switch par défaut
        expirationSwitch.setChecked(true);
        // Assombrir le bouton si le switch est désactivé au démarrage
        selectExpirationDate.setAlpha(1.0f); // Par défaut, à pleine luminosité
        selectExpirationDate.setEnabled(true); // Activation initiale

        // Gestion du switch expiration
        expirationSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            selectExpirationDate.setEnabled(isChecked);
            if (!isChecked) {
                expirationDate = "";
                selectExpirationDate.setAlpha(0.5f);
                updateDateButton();
            } else {
                selectExpirationDate.setAlpha(1.0f);
            }
        });

        // Ouvrir le DatePickerDialog lors du clic sur le bouton de sélection de date
        selectExpirationDate.setOnClickListener(v -> showDatePickerDialog());

        // Gestion de la quantité avec boutons + et -
        increaseQuantity.setOnClickListener(v -> {
            quantity++;
            productQuantity.setText(String.valueOf(quantity));
        });

        decreaseQuantity.setOnClickListener(v -> {
            if (quantity > 1) {
                quantity--;
                productQuantity.setText(String.valueOf(quantity));
            }
        });

        // Appel de la méthode fetchProductInfo si le code-barres est disponible
        if (scannedCode != null && !scannedCode.isEmpty()) {
            fetchProductInfo(scannedCode); // Remplir automatiquement le nom et l'image
        }

        addProductButton.setOnClickListener(v -> saveProduct());

        cancelProductButton.setOnClickListener(view -> finish());
    }

    @SuppressLint("StaticFieldLeak")
    private void fetchProductInfo(String barcode) {
        new AsyncTask<Void, Void, JSONObject>() {
            @Override
            protected JSONObject doInBackground(Void... voids) {
                String apiUrl = "https://api.ustock.totooche.fr:8443/products/" + barcode;
                try {
                    // 1. Essayer de récupérer le produit avec GET
                    HttpURLConnection connection = (HttpURLConnection) new URL(apiUrl).openConnection();
                    connection.setRequestMethod("GET");

                    if (connection.getResponseCode() == HttpURLConnection.HTTP_OK) {
                        return parseResponse(connection);
                    } else if (connection.getResponseCode() == HttpURLConnection.HTTP_NOT_FOUND) {
                        // 2. Si non trouvé, essayer de l'ajouter avec POST
                        if (addProductToDatabase(barcode)) {
                            // 3. Après l'ajout, refaire un GET
                            connection = (HttpURLConnection) new URL(apiUrl).openConnection();
                            connection.setRequestMethod("GET");
                            if (connection.getResponseCode() == HttpURLConnection.HTTP_OK) {
                                return parseResponse(connection);
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
                return null;
            }

            @Override
            protected void onPostExecute(JSONObject jsonObject) {
                if (jsonObject != null) {
                    try {
                        if (jsonObject.has("product_name")) {
                            productName.setText(jsonObject.getString("product_name"));
                        }
                        if (jsonObject.has("brand")) {
                            String brand = jsonObject.getString("brand");
                            // Tu peux afficher la marque ici si nécessaire
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } else {
                    Toast.makeText(AddProductActivity.this, "Erreur de récupération des informations", Toast.LENGTH_SHORT).show();
                }
            }
        }.execute();
    }

    // Méthode pour envoyer une requête POST si le produit n'existe pas
    private boolean addProductToDatabase(String barcode) {
        try {
            String apiUrl = "https://api.ustock.totooche.fr:8443/products/?barcode=" + barcode;
            HttpURLConnection connection = (HttpURLConnection) new URL(apiUrl).openConnection();
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Accept", "application/json");
            connection.setDoOutput(true);

            // Envoyer une requête POST avec un corps vide
            connection.getOutputStream().write("".getBytes());
            connection.getOutputStream().flush();
            connection.getOutputStream().close();

            return connection.getResponseCode() == HttpURLConnection.HTTP_CREATED || connection.getResponseCode() == HttpURLConnection.HTTP_OK;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // Méthode pour lire et parser la réponse JSON
    private JSONObject parseResponse(HttpURLConnection connection) throws Exception {
        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
        StringBuilder response = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            response.append(line);
        }
        reader.close();
        return new JSONObject(response.toString());
    }

    private void showDatePickerDialog() {
        DatePickerDialog datePickerDialog = new DatePickerDialog(this,
                (view, year, month, dayOfMonth) -> {
                    calendar.set(year, month, dayOfMonth);
                    updateDateButton();
                },
                calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH), calendar.get(Calendar.DAY_OF_MONTH)
        );
        datePickerDialog.show();
    }

    private void updateDateButton() {
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy", Locale.getDefault());
        expirationDate = dateFormat.format(calendar.getTime());
        selectExpirationDate.setText(expirationDate);
    }

    private void saveProduct() {
        String name = productName.getText().toString().trim();
        String selectedList = listSelector.getSelectedItem().toString();
        boolean hasExpiration = expirationSwitch.isChecked();

        if (name.isEmpty() || selectedList.isEmpty()) {
            Toast.makeText(this, "Veuillez remplir tous les champs obligatoires", Toast.LENGTH_SHORT).show();
            return;
        }

        SharedPreferences.Editor editor = sharedPreferences.edit();
        Set<String> items = new HashSet<>(sharedPreferences.getStringSet(selectedList, new HashSet<>()));

        String productEntry = name + " | Code: " + scannedCode + " | Quantité: " + quantity;
        if (hasExpiration) {
            productEntry += " | Expiration: " + expirationDate;
        }

        items.add(productEntry);
        editor.putStringSet(selectedList, items);
        editor.apply();

        Toast.makeText(this, "Produit ajouté à " + selectedList, Toast.LENGTH_SHORT).show();
        finish();
    }
}