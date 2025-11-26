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

import android.net.Uri
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.action.actionParametersOf
import androidx.glance.layout.Alignment
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxWidth
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import com.example.bible.R

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
            Color(0xFF111318) // Dark background
        } else {
            Color(0xFFf9f9ff) // Light background
        }

        val textColor = if (isDarkMode) {
            ColorProvider(Color(0xFFe2e2e9)) // Light text for dark background
        } else {
            ColorProvider(Color(0xFF1a1b20)) // Dark text for light background
        }

        val textSize = if (verseText.length <= 300) {
            14.sp
        } else {
            12.sp
        }

        Box(
            modifier = GlanceModifier
                .background(backgroundColor)
                .padding(16.dp)
        ) {
            Column {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                ) {
                    if (verseReference.isNotEmpty()) {
                        Text(
                            verseReference,
                            style = TextStyle(
                                fontSize = 12.sp,
                                color = textColor,
                            ),
                            modifier = GlanceModifier.defaultWeight()
                        )
                    }
                    Image(
                        provider = ImageProvider(R.drawable.ic_check),
                        contentDescription = "Mark as Read",
                        modifier = GlanceModifier.clickable(
                            onClick = actionRunCallback<MarkReadAction>(
                                actionParametersOf(MarkReadAction.verseRefKey to verseReference)
                            )
                        )
                    )
                }

                Text(
                    verseText,
                    style = TextStyle(
                        fontSize = textSize,
                        color = textColor,
                    ),
                )
            }
        }
    }
}

class MarkReadAction : ActionCallback {
    companion object {
        val verseRefKey = ActionParameters.Key<String>("verseRef")
    }

    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val verseRef = parameters[verseRefKey] ?: ""
        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("homeWidgetExample://markRead?ref=${Uri.encode(verseRef)}")
        )
        backgroundIntent.send()
    }
}
