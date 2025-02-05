package com.example.ustock_app;

import android.os.Bundle;
import android.widget.Button;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.journeyapps.barcodescanner.ScanContract;
import com.journeyapps.barcodescanner.ScanOptions;

public class BarcodeScannerActivity extends AppCompatActivity {

    // Initialisation du lanceur pour scanner le code-barres
    private final androidx.activity.result.ActivityResultLauncher<ScanOptions> barcodeLauncher = registerForActivityResult(
            new ScanContract(),
            result -> {
                if (result.getContents() != null) {
                    Toast.makeText(BarcodeScannerActivity.this, "Code Scanné: " + result.getContents(), Toast.LENGTH_LONG).show();
                } else {
                    Toast.makeText(BarcodeScannerActivity.this, "Aucun code scanné", Toast.LENGTH_SHORT).show();
                }
            }
    );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_barcode_scanner); // Utilise le bon layout
        ScanOptions options = new ScanOptions();
        options.setPrompt("Placez le code-barres devant la caméra");
        options.setBeepEnabled(true);  // Active un bip sonore lors du scan
        options.setOrientationLocked(true);  // Verrouille l'orientation
        options.setCaptureActivity(PortraitCaptureActivity.class);  // Utilise une activité personnalisée pour forcer le mode portrait
        barcodeLauncher.launch(options);
    }
}
