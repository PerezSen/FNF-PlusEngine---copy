package objects;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
import openfl.display.BitmapData;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxG;

class VideoSmootherShader extends FlxShader {
    @:glFragmentSource('
        #pragma header
        uniform sampler2D prevTexture;
        uniform float blend;
        void main() {
            vec2 uv = openfl_TextureCoordv;
            vec4 c = flixel_texture2D(bitmap, uv);
            vec4 p = texture2D(prevTexture, uv);
            if (p.a < 0.1) {
                gl_FragColor = c;
            } else {
                gl_FragColor = mix(p, c, blend);
            }
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
    var videoFPS:Float = 30.0; // Ajusta si tus videos son de 60
    var isInitialized:Bool = false;

    public function new() {
        super();
        smoothShader = new VideoSmootherShader();
        this.shader = smoothShader;
        // Creamos un bitmap inicial negro pero transparente
        previousFrame = new BitmapData(1, 1, true, 0x00000000);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // PROTECCIÓN 1: Si no se está reproduciendo, no hacer nada
        if(bitmap == null || !bitmap.isPlaying) {
            isInitialized = false;
            return;
        }

        var currentTime:Float = haxe.Int64.toInt(bitmap.time);

        // PROTECCIÓN 2: Detectar "Saltos de tiempo" (Loops o Lags)
        // Si el tiempo saltó hacia atrás (loop) o avanzó demasiado rápido (lag), reseteamos
        if (Math.abs(currentTime - lastTime) > 1000) {
            lastTime = currentTime;
            frameTimer = 0;
            smoothShader.blend.value = [0.0]; // Mostrar frame actual puro
            return;
        }

        // Si detectamos un cambio de frame en el video
        if (currentTime != lastTime) {
            // PROTECCIÓN 3: Validar que el gráfico exista y tenga tamaño real
            if (graphic != null && graphic.bitmap != null && graphic.bitmap.width > 10) {
                
                // Redimensionar el buffer si el video cambió de tamaño (ej. al cargar otro video)
                if (previousFrame.width != graphic.bitmap.width || previousFrame.height != graphic.bitmap.height) {
                    previousFrame.dispose();
                    previousFrame = new BitmapData(graphic.bitmap.width, graphic.bitmap.height, true, 0x00000000);
                }

                try {
                    // Guardamos la foto del frame anterior
                    previousFrame.draw(graphic.bitmap);
                    isInitialized = true;
                } catch(e:Dynamic) {
                    // Si falla el dibujo (raro), no actualizamos y abortamos interpolación por este frame
                    trace("Error capturando frame de video: " + e);
                }
            }
            
            // Pasamos el frame guardado al shader
            if(isInitialized) {
                smoothShader.prevTexture.input = previousFrame;
            }
            
            lastTime = currentTime;
            frameTimer = 0;
            smoothShader.blend.value = [0.0];
        } 
        else {
            // Lógica de interpolación (Suavizado)
            if (isInitialized) {
                frameTimer += elapsed;
                
                var maxTime:Float = 1.0 / videoFPS;
                // Evitamos división por cero
                if (maxTime <= 0) maxTime = 0.033; 

                var alpha:Float = frameTimer / maxTime;
                
                // Limitamos a 1.0 (Frame nuevo completo)
                if(alpha > 1) alpha = 1;
                
                // PROTECCIÓN 4: Si el blend es muy cercano a 1, forzamos 1 para evitar "fantasmas" tardíos
                if(alpha > 0.9) alpha = 1;

                smoothShader.blend.value = [alpha];
            } else {
                // Si no está inicializado, mostramos el video normal sin efectos
                smoothShader.blend.value = [1.0];
            }
        }
    }
}
#end
