package com.example.ustock_app;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        LinearLayout textView = findViewById(R.id.All_Layout);
        Button barcode_button = findViewById(R.id.barcode_button);

        // Définir l'action lors du clic sur le TextView
        textView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, AllPageActivity.class);
                startActivity(intent);
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
}