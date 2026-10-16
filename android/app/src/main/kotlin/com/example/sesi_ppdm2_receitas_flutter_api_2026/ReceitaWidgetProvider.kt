package com.example.sesi_ppdm2_receitas_flutter_api_2026

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Shader
import android.graphics.RectF
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import kotlin.random.Random

class ReceitaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        val receitas = try {
            JSONArray(widgetData.getString("receitas_widget", "[]"))
        } catch (_: Exception) {
            JSONArray()
        }

        if (receitas.length() == 0) return

        val indiceAnterior = widgetData.getInt("receita_widget_indice", -1)
        val indice = if (receitas.length() > 1 && indiceAnterior in 0 until receitas.length()) {
            val sorteado = Random.nextInt(receitas.length() - 1)
            if (sorteado >= indiceAnterior) sorteado + 1 else sorteado
        } else {
            Random.nextInt(receitas.length())
        }
        val receita = receitas.getJSONObject(indice)
        widgetData.edit().putInt("receita_widget_indice", indice).apply()

        val nome = receita.optString("nome", "Receita")
        val caminhoImagem = receita.optString("imagem", "")
        val bitmap = if (caminhoImagem.isNotEmpty()) {
            BitmapFactory.decodeFile(caminhoImagem)?.let(::imagemCircular)
        } else {
            null
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.receita_widget)
            views.setTextViewText(R.id.widget_receita_nome, nome)
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_receita_imagem, bitmap)
            } else {
                views.setImageViewResource(
                    R.id.widget_receita_imagem,
                    android.R.drawable.ic_menu_report_image,
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun imagemCircular(imagem: Bitmap): Bitmap {
        val tamanho = minOf(imagem.width, imagem.height)
        val deslocamentoX = (imagem.width - tamanho) / 2f
        val deslocamentoY = (imagem.height - tamanho) / 2f
        val escala = 256f / tamanho
        val matriz = Matrix().apply {
            setScale(escala, escala)
            postTranslate(-deslocamentoX * escala, -deslocamentoY * escala)
        }
        val pintura = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = BitmapShader(imagem, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
            shader.setLocalMatrix(matriz)
        }
        val circular = Bitmap.createBitmap(256, 256, Bitmap.Config.ARGB_8888)
        Canvas(circular).drawOval(RectF(0f, 0f, 256f, 256f), pintura)
        return circular
    }
}