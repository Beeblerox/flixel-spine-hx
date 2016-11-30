package flixel.addons.display;

import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

import openfl.geom.Matrix;

// TODO: need to make a lot of optimizations here and in FlxSprite as well...

class FlxTransformableSprite extends FlxSprite {

    public var transformMatrix:Matrix;
	
	private var _vRect:FlxRect = FlxRect.get();
	private var _vPoint:FlxPoint = FlxPoint.get();

    override public function destroy():Void
    {
		transformMatrix = null;
		_vRect = FlxDestroyUtil.put(_vRect);
		_vPoint = FlxDestroyUtil.put(_vPoint);
		
		super.destroy();
    }

    override function drawComplex(camera:FlxCamera):Void
    {
        _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
        _matrix.translate(-origin.x, -origin.y);
        _matrix.scale(scale.x, scale.y);
		
        if (bakedRotationAngle <= 0)
        {
            updateTrig();
			
            if (angle != 0)
                _matrix.rotateWithTrig(_cosAngle, _sinAngle);
        }
		
        _point.addPoint(origin);
        //if (isPixelPerfectRender(camera))
        //    _point.floor();
		
        _matrix.translate(_point.x, _point.y);
		
        if (transformMatrix != null)
            _matrix.concat(transformMatrix);
		
        camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing);
    }

    override public function isSimpleRender(?camera:FlxCamera):Bool
    {
        if (FlxG.renderBlit)
            return super.isSimpleRender(camera) && transformMatrix == null;
        else
            return false;
    }

    override public function isOnScreen(?Camera:FlxCamera):Bool 
	{
		if (transformMatrix == null)
			return super.isOnScreen(Camera);
		
		if (Camera == null)
			Camera = FlxG.camera;
		
		_matrix.identity();
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);
		
		if (bakedRotationAngle <= 0)
        {
            updateTrig();
			
            if (angle != 0)
                _matrix.rotateWithTrig(_cosAngle, _sinAngle);
        }
		
		getScreenPosition(_point, Camera).subtractPoint(offset).addPoint(origin);
		
		_matrix.translate(_point.x, _point.y);
		
		if (transformMatrix != null)
			_matrix.concat(transformMatrix);
		
		var a = _matrix.a;
		var b = _matrix.b;
		var c = _matrix.c;
		var d = _matrix.d;
		var tx = _matrix.tx;
		var ty = _matrix.ty;
		
		// p1 - top left corner
		var x1:Float = tx;
		var y1:Float = ty;
		
		// p2 - top right corner
		var x2:Float = frameWidth * a + tx;
		var y2:Float = frameWidth * b + ty;
		
		// p3 - bottom right corner
		var x3:Float = frameWidth * a + frameHeight * c + tx;
		var y3:Float = frameWidth * b + frameHeight * d + ty;
		
		// p4 - bottom left corner
		var x4:Float = frameHeight * c + tx;
		var y4:Float = frameHeight * d + ty;
		
		_vRect.set(x1, y1);
		_vPoint.set(x2, y2);
		_vRect.unionWithPoint(_vPoint);
		_vPoint.set(x3, y3);
		_vRect.unionWithPoint(_vPoint);
		_vPoint.set(x4, y4);
		_vRect.unionWithPoint(_vPoint);
		
		return !(_vRect.x > Camera.width || _vRect.right < 0 || _vRect.y > Camera.height || _vRect.bottom < 0);
    }
}