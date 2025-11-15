package com.example.bible.widget

import android.content.Context
import android.content.res.Configuration
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition

class AppWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>?
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            GlanceContent(context, state)
        }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
        val prefs = currentState.preferences
        val verseText = prefs.getString("verse_text", "") ?: ""
        val verseReference = prefs.getString("verse_reference", "") ?: ""

        // Detect system theme
        val isDarkMode = (context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

        // Theme-aware colors
        val backgroundColor = if (isDarkMode) {
            Color(0xFF1E1E1E) // Dark background
        } else {
            Color(0xFFFFFFFF) // Light background
        }

        val textColor = if (isDarkMode) {
            ColorProvider(Color(0xFFE0E0E0)) // Light text for dark background
        } else {
            ColorProvider(Color(0xFF000000)) // Dark text for light background
        }

        Box(
            modifier = GlanceModifier
                .background(backgroundColor)
                .padding(16.dp)
        ) {
            Column {
                if (verseReference.isNotEmpty()) {
                    Text(
                        verseReference,
                        style = TextStyle(
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = textColor,
                        ),
                    )
                }
                Text(
                    verseText,
                    style = TextStyle(
                        fontSize = 16.sp,
                        color = textColor,
                    ),
                )
            }
        }
    }
}

