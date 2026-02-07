package objects;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
import openfl.display.BitmapData;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxG;

// Definimos el Shader aquí mismo para rápido
class VideoSmootherShader extends FlxShader {
    @:glFragmentSource('
        #pragma header
        uniform sampler2D prevTexture;
        uniform float blend;
        void main() {
            vec2 uv = openfl_TextureCoordv;
            vec4 c = flixel_texture2D(bitmap, uv);
            vec4 p = texture2D(prevTexture, uv);
            gl_FragColor = mix(p, c, blend);
        }
    ')
    public function new() {
        super();
        blend.value = [0.0];
    }
}

class SmoothVideoSprite extends FlxVideoSprite {
    var smoothShader:VideoSmootherShader;
    var previousFrame:BitmapData;
    var lastTime:Float = -1;
    var frameTimer:Float = 0;
    
    // Asumimos videos de 30FPS (estándar FNF). Si usas de 60, cambia esto a 60.0
    var videoFPS:Float = 30.0; 

    public function new() {
        super();
        smoothShader = new VideoSmootherShader();
        this.shader = smoothShader;
        previousFrame = new BitmapData(1, 1, true, 0x00000000);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(bitmap == null || !bitmap.isPlaying) return;

        // Obtenemos el tiempo actual del video (convertimos Int64 a Float)
        var currentTime:Float = haxe.Int64.toInt(bitmap.time);

        // Si el tiempo cambió, significa que el video soltó un frame nuevo
        if (currentTime != lastTime) {
            // Guardamos el frame anterior en el buffer
            if (graphic != null && graphic.bitmap != null) {
                if (previousFrame.width != graphic.bitmap.width || previousFrame.height != graphic.bitmap.height) {
                    previousFrame.dispose();
                    previousFrame = new BitmapData(graphic.bitmap.width, graphic.bitmap.height, true, 0);
                }
                previousFrame.draw(graphic.bitmap);
            }
            
            // Pasamos el frame guardado al shader
            smoothShader.prevTexture.input = previousFrame;
            
            // Reseteamos
            lastTime = currentTime;
            frameTimer = 0;
            smoothShader.blend.value = [0.0];
        } 
        else {
            // INTERPOLACIÓN (El efecto Xiaomi)
            frameTimer += elapsed;
            
            // Calculamos cuánto porcentaje avanzar (Lerp)
            var maxTime:Float = 1.0 / videoFPS;
            var alpha:Float = frameTimer / maxTime;
            
            if(alpha > 1) alpha = 1;
            
            // Le decimos al shader que mezcle los frames
            smoothShader.blend.value = [alpha];
        }
    }
}
#end
