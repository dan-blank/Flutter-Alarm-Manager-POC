package com.example.flutter_alarm_manager_poc.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Snooze
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.flutter_alarm_manager_poc.utils.convertMillisToDate
import com.example.flutter_alarm_manager_poc.utils.convertMillisToTime

@Composable
fun AlarmScreen(
    onAccept: (Int, Int, String) -> Unit,
    onDecline: () -> Unit,
    onSnooze: () -> Unit
) {
    var question1Selection by remember { mutableStateOf<Int?>(null) }
    var question2Selection by remember { mutableStateOf<Int?>(null) }
    var additionalText by remember { mutableStateOf("") }

    // Reinstated Exit Condition 1: Answering all questions automatically triggers the accept action.
    LaunchedEffect(question1Selection, question2Selection) {
        // Storing in local variables for stability within the coroutine scope
        val q1 = question1Selection
        val q2 = question2Selection

        // If both questions have been answered, trigger the accept action, including any text.
        if (q1 != null && q2 != null) {
            onAccept(q1, q2, additionalText)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.SpaceAround,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Column(
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = convertMillisToTime(System.currentTimeMillis()),
                style = MaterialTheme.typography.displayMedium,
                color = Color.White,
                modifier = Modifier.padding(bottom = 32.dp)
            )
            Text(
                text = convertMillisToDate(System.currentTimeMillis()),
                style = MaterialTheme.typography.titleMedium,
                color = Color.White,
                modifier = Modifier.padding(bottom = 32.dp)
            )
        }

        Column(
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            QuestionSection(
                question = "How are you feeling?",
                selectedOption = question1Selection,
                onOptionSelected = { question1Selection = it }
            )
            QuestionSection(
                question = "How did you sleep?",
                selectedOption = question2Selection,
                onOptionSelected = { question2Selection = it }
            )
            OutlinedTextField(
                value = additionalText,
                onValueChange = { additionalText = it },
                label = { Text("Additional information (optional)") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp),
                colors = TextFieldDefaults.colors(
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    cursorColor = Color.White,
                    focusedContainerColor = Color.Transparent,
                    unfocusedContainerColor = Color.Transparent,
                    focusedIndicatorColor = Color.White,
                    unfocusedIndicatorColor = Color.Gray,
                    focusedLabelColor = Color.White,
                    unfocusedLabelColor = Color.Gray,
                ),
                maxLines = 3
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceAround
        ) {
            // Exit condition 2: Clicking the "Decline" button.
            ButtonAction(
                icon = Icons.Filled.Close,
                text = "Decline",
                onClick = onDecline
            )
            // Exit condition 3: Clicking the "Snooze" button.
            ButtonAction(
                icon = Icons.Filled.Snooze,
                text = "Snooze",
                onClick = onSnooze
            )
        }
    }
}

@Composable
fun ButtonAction(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    text: String,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = modifier
                .size(60.dp)
                .background(color = Color.White, shape = CircleShape)
                .clickable {
                    onClick()
                }
        ) {
            Icon(
                imageVector = icon,
                contentDescription = text,
                tint = Color(0xFF8A2BE2),
                modifier = Modifier
                    .size(40.dp)
                    .align(Alignment.Center)
            )
        }
        Text(
            modifier = Modifier.padding(top = 8.dp),
            text = text,
            style = TextStyle(color = Color.White, fontStyle = FontStyle.Normal)
        )
    }
}

@Preview
@Composable
fun QuestionSection(
    question: String,
    selectedOption: Int?,
    onOptionSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = question,
            style = MaterialTheme.typography.titleMedium,
            color = Color.White
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            (1..3).forEach { option ->
                Row(verticalAlignment = Alignment.CenterVertically) {
                    RadioButton(
                        selected = (selectedOption == option),
                        onClick = { onOptionSelected(option) },
                        colors = RadioButtonDefaults.colors(
                            selectedColor = Color.White,
                            unselectedColor = Color.Gray
                        )
                    )
                    Text(
                        text = option.toString(),
                        style = MaterialTheme.typography.bodyLarge,
                        color = Color.White
                    )
                }
            }
        }
    }
}