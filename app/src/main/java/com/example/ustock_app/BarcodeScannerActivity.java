package com.example.ustock_app;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;
import androidx.activity.result.ActivityResultLauncher;
import androidx.appcompat.app.AppCompatActivity;
import com.journeyapps.barcodescanner.ScanContract;
import com.journeyapps.barcodescanner.ScanOptions;

public class BarcodeScannerActivity extends AppCompatActivity {

    private final ActivityResultLauncher<ScanOptions> barcodeLauncher = registerForActivityResult(
            new ScanContract(),
            result -> {
                if (result.getContents() != null) {
                    Toast.makeText(BarcodeScannerActivity.this, "Code Scanné: " + result.getContents(), Toast.LENGTH_LONG).show();
                } else {
                    Toast.makeText(BarcodeScannerActivity.this, "Aucun code scanné", Toast.LENGTH_SHORT).show();
                }
                // Redirection vers MainActivity après le scan
                Intent intent = new Intent(BarcodeScannerActivity.this, MainActivity.class);
                startActivity(intent);
                finish(); // Ferme BarcodeScannerActivity
            }
    );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_barcode_scanner);
        ScanOptions options = new ScanOptions();
        options.setPrompt("Placez le code-barres devant la caméra");
        options.setBeepEnabled(true);
        options.setOrientationLocked(true);
        options.setCaptureActivity(PortraitCaptureActivity.class);
        barcodeLauncher.launch(options);
    }
}