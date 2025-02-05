package com.example.ustock_app;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class ListDetailActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list_detail);

        TextView listTitle = findViewById(R.id.listTitle);
        String listName = getIntent().getStringExtra("list_name");
        listTitle.setText(listName);

        Button homeButton = findViewById(R.id.homeButton);
        homeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(ListDetailActivity.this, MainActivity.class);
                startActivity(intent);
                finish();
            }
        });
    }
}