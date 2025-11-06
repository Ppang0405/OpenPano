// Example usage of OpenPano Kotlin bindings for Android
//
// Add to your app/build.gradle:
// dependencies {
//     implementation files('libs/openpano.aar')
// }

package com.example.openpano

import com.openpano.*
import java.io.File

fun main(args: Array<String>) {
    if (args.size < 2) {
        println("Usage: kotlin_example <image1> <image2> [image3] ...")
        println("Example: kotlin_example img1.jpg img2.jpg img3.jpg")
        return
    }
    
    val imagePaths = args.toList()
    
    println("OpenPano Kotlin Example")
    println("=".repeat(40))
    println()
    
    // Check if files exist
    for (path in imagePaths) {
        val file = File(path)
        if (!file.exists()) {
            println("Error: File not found: $path")
            return
        }
    }
    
    // Create configuration
    val config = PanoConfig(
        cylinderMode = false,
        estimateCamera = true,
        transMode = false,
        orderedInput = false,
        crop = true,
        focalLength = 37.0f,
        maxOutputSize = 8000
    )
    
    println("Configuration:")
    println("  Estimate camera: ${config.estimateCamera}")
    println("  Cylinder mode: ${config.cylinderMode}")
    println("  Crop: ${config.crop}")
    println("  Max output size: ${config.maxOutputSize}")
    println()
    
    // Add images
    println("Adding ${imagePaths.size} images:")
    imagePaths.forEachIndexed { i, path ->
        println("  [${i + 1}] $path")
    }
    println()
    
    // Stitch
    println("Stitching images... (this may take a while)")
    val start = System.currentTimeMillis()
    
    try {
        val panorama = stitchPanorama(imagePaths, config)
        val duration = (System.currentTimeMillis() - start) / 1000.0
        
        println("✓ Stitching completed in %.2fs".format(duration))
        println()
        
        // Print info
        println("Result:")
        println("  Width: ${panorama.width()} px")
        println("  Height: ${panorama.height()} px")
        println("  Channels: ${panorama.channels()}")
        println("  Total pixels: ${panorama.width() * panorama.height()}")
        println()
        
        // Save
        val outputPath = "panorama_output.jpg"
        println("Saving to '$outputPath'...")
        panorama.save(outputPath)
        
        println("✓ Done!")
        
        // Optional: Get raw bytes for further processing
        // val bytesData = panorama.toBytes()
        // println("  Raw data size: ${bytesData.size} bytes")
        
    } catch (e: PanoException.StitchError) {
        println("Stitching failed: ${e.message}")
    } catch (e: PanoException.SaveError) {
        println("Save failed: ${e.message}")
    } catch (e: Exception) {
        println("Unexpected error: ${e.message}")
    }
}

// Android Activity Example
class PanoramaActivity : AppCompatActivity() {
    
    private suspend fun stitchImages(imagePaths: List<String>): Panorama? {
        return withContext(Dispatchers.IO) {
            try {
                val config = PanoConfig(
                    cylinderMode = false,
                    estimateCamera = true,
                    transMode = false,
                    orderedInput = false,
                    crop = true,
                    focalLength = 37.0f,
                    maxOutputSize = 8000
                )
                
                stitchPanorama(imagePaths, config)
            } catch (e: PanoException) {
                Log.e("PanoramaActivity", "Stitching failed", e)
                null
            }
        }
    }
    
    private fun showPanorama(panorama: Panorama) {
        // Convert to Android Bitmap
        val width = panorama.width().toInt()
        val height = panorama.height().toInt()
        val bytes = panorama.toBytes()
        
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val buffer = ByteBuffer.wrap(bytes)
        bitmap.copyPixelsFromBuffer(buffer)
        
        // Display in ImageView
        imageView.setImageBitmap(bitmap)
        
        // Or save
        val outputFile = File(getExternalFilesDir(null), "panorama.jpg")
        panorama.save(outputFile.absolutePath)
    }
}

