package com.example.ustock_app;

import android.content.Intent;
import android.graphics.PorterDuff;
import android.os.Bundle;
import android.widget.ImageView;

import androidx.appcompat.app.AppCompatActivity;

public class ShopList extends AppCompatActivity {

    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.shop_list_activity);

        ImageView MyProduct = findViewById(R.id.myProductPage);

        MyProduct.setOnClickListener(view -> {
            Intent intent = new Intent(ShopList.this, MainActivity.class);
            startActivity(intent);
        });

        ImageView currentActivityIcon = findViewById(R.id.shopListPageButton); // ID de l'image
        currentActivityIcon.setColorFilter(getResources().getColor(R.color.selected_color), PorterDuff.Mode.SRC_IN);
    }
}
