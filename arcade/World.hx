package arcade;

/**
* @author       Richard Davey <rich@photonstorm.com>
* @copyright    2016 Photon Storm Ltd.
* @license      {@link https://github.com/photonstorm/phaser/blob/master/license.txt|MIT License}
*/

/**
* The Arcade Physics world. Contains Arcade Physics related collision, overlap and motion methods.
*
* @class Phaser.Physics.Arcade
* @constructor
*/
class World {

    /** The World gravity X setting. Defaults to 0 (no gravity). */
    public var gravityX:Float = 0;

    /** The World gravity Y setting. Defaults to 0 (no gravity). */
    public var gravityY:Float = 0;

    // The bounds inside of which the physics world exists.
    public var boundsX:Float = 0;
    public var boundsY:Float = 0;
    public var boundsWidth:Float = 0;
    public var boundsHeight:Float = 0;

    // Which edges of the World bounds Bodies can collide against when `collideWorldBounds` is `true`.
    // For example checkCollisionDown = false means Bodies cannot collide with the World.bounds.bottom.
    // @property {object} checkCollision - An object containing allowed collision flags (up, down, left, right).
    public var checkCollisionNone:Bool = false;
    public var checkCollisionUp:Bool = true;
    public var checkCollisionDown:Bool = true;
    public var checkCollisionLeft:Bool = true;
    public var checkCollisionRight:Bool = true;

    /** Used by the QuadTree to set the maximum number of objects per quad. */
    public var maxObjects:Int = 10;

    /** Used by the QuadTree to set the maximum number of iteration levels. */
    public var maxLevels:Int = 4;

    /** A value added to the delta values during collision checks. Increase it to prevent sprite tunneling. */
    public var overlapBias:Float = 4;

    /** If true World.separate will always separate on the X axis before Y. Otherwise it will check gravity totals first. */
    public var forceX:Bool = false;

    /** Used when colliding a Sprite vs. a Group, or a Group vs. a Group, this defines the direction the sort is based on. Default is `LEFT_RIGHT`. */
    public var sortDirection:SortDirection = SortDirection.LEFT_RIGHT;

    /** If true the QuadTree will not be used for any collision. QuadTrees are great if objects are well spread out in your game, otherwise they are a performance hit. If you enable this you can disable on a per body basis via `Body.skipQuadTree`. */
    public var skipQuadTree:Bool = true;

    /** If `true` the `Body.preUpdate` method will be skipped, halting all motion for all bodies. Note that other methods such as `collide` will still work, so be careful not to call them on paused bodies. */
    public var isPaused:Bool = false;

    /** The world QuadTree. */
    public var quadTree:QuadTree = null;

    /** Elapsed time since last tick. */
    public var elapsed:Float = 0;

    /** Internal cache var. */
    private var _total:Int = 0;

    public function new(boundsX:Float, boundsY:Float, boundsWidth:Float, boundsHeight:Float) {

        this.boundsX = boundsX;
        this.boundsY = boundsY;
        this.boundsWidth = boundsWidth;
        this.boundsHeight = boundsHeight;

        this.quadTree = new QuadTree(this.boundsX, this.boundsY, this.boundsWidth, this.boundsHeight, this.maxObjects, this.maxLevels);

    } //new

    /**
     * Updates the size of this physics world.
     *
     * @method Phaser.Physics.Arcade#setBounds
     * @param {number} x - Top left most corner of the world.
     * @param {number} y - Top left most corner of the world.
     * @param {number} width - New width of the world. Can never be smaller than the Game.width.
     * @param {number} height - New height of the world. Can never be smaller than the Game.height.
     */
    inline public function setBounds(x:Float, y:Float, width:Float, height:Float):Void {

        this.boundsX = x;
        this.boundsY = y;
        this.boundsWidth = width;
        this.boundsHeight = height;

    } //setBounds

    /**
     * Creates an Arcade Physics body on the given game object.
     *
     * A game object can only have 1 physics body active at any one time, and it can't be changed until the body is nulled.
     *
     * When you add an Arcade Physics body to an object it will automatically add the object into its parent Groups hash array.
     *
     * @method Phaser.Physics.Arcade#enableBody
     * @param {object} object - The game object to create the physics body on. A body will only be created if this object has a null `body` property.
     */
    public function enableBody(body:Body):Void {

        // TODO?

    } //enableBody

    /**
     * Called automatically by a Physics body, it updates all motion related values on the Body unless `World.isPaused` is `true`.
     *
     * @method Phaser.Physics.Arcade#updateMotion
     * @param {Phaser.Physics.Arcade.Body} The Body object to be updated.
     */
    inline public function updateMotion(body:Body):Void
    {

        if (body.allowRotation)
        {
            var velocityDelta = computeVelocity(0, body, body.angularVelocity, body.angularAcceleration, body.angularDrag, body.maxAngular) - body.angularVelocity;
            body.angularVelocity += velocityDelta;
            body.rotation += (body.angularVelocity * elapsed);
        }

        body.velocityX = computeVelocity(1, body, body.velocityX, body.acceleration.x, body.drag.x, body.maxVelocity.x);
        body.velocityY = computeVelocity(2, body, body.velocityY, body.acceleration.y, body.drag.y, body.maxVelocity.y);

    } //updateMotion

    /**
     * A tween-like function that takes a starting velocity and some other factors and returns an altered velocity.
     * Based on a function in Flixel by @ADAMATOMIC
     *
     * @method Phaser.Physics.Arcade#computeVelocity
     * @param {number} axis - 0 for nothing, 1 for horizontal, 2 for vertical.
     * @param {Phaser.Physics.Arcade.Body} body - The Body object to be updated.
     * @param {number} velocity - Any component of velocity (e.g. 20).
     * @param {number} acceleration - Rate at which the velocity is changing.
     * @param {number} drag - Really kind of a deceleration, this is how much the velocity changes if Acceleration is not set.
     * @param {number} [max=10000] - An absolute value cap for the velocity.
     * @return {number} The altered Velocity value.
     */
    inline public function computeVelocity(axis:Axis, body:Body, velocity:Float, acceleration:Float, drag:Float, max:Float = 10000):Float
    {

        if (axis == Axis.HORIZONTAL && body.allowGravity)
        {
            velocity += (this.gravityX + body.gravityX) * elapsed;
        }
        else if (axis == Axis.VERTICAL && body.allowGravity)
        {
            velocity += (this.gravityY + body.gravityY) * elapsed;
        }

        if (acceleration)
        {
            velocity += acceleration * elapsed;
        }
        else if (drag != 0 && body.allowDrag)
        {
            drag *= elapsed;

            if (velocity - drag > 0)
            {
                velocity -= drag;
            }
            else if (velocity + drag < 0)
            {
                velocity += drag;
            }
            else
            {
                velocity = 0;
            }
        }

        if (velocity > max)
        {
            velocity = max;
        }
        else if (velocity < -max)
        {
            velocity = -max;
        }

        return velocity;

    } //computeVelocity

    /**
     * Checks for overlaps between two game objects. The objects can be Sprites, Groups or Emitters.
     *
     * Unlike {@link #collide} the objects are NOT automatically separated or have any physics applied, they merely test for overlap results.
     *
     * You can perform Sprite vs. Sprite, Sprite vs. Group and Group vs. Group overlap checks.
     * Both the first and second parameter can be arrays of objects, of differing types.
     * If two arrays are passed, the contents of the first parameter will be tested against all contents of the 2nd parameter.
     *
     * **This function is not recursive**, and will not test against children of objects passed (i.e. Groups within Groups).
     *
     * ##### Tilemaps
     *
     * Any overlapping tiles, including blank/null tiles, will give a positive result. Tiles marked via {@link Phaser.Tilemap#setCollision} (and similar methods) have no special status, and callbacks added via {@link Phaser.Tilemap#setTileIndexCallback} or {@link Phaser.Tilemap#setTileLocationCallback} are not invoked. So calling this method without any callbacks isn't very useful.
     *
     * If you're interested only in whether an object overlaps a certain tile or class of tiles, filter the tiles with `processCallback` and then use the result returned by this method. Blank/null tiles can be excluded by their {@link Phaser.Tile#index index} (-1).
     *
     * If you want to take action on certain overlaps, examine the tiles in `collideCallback` and then handle as you like.
     *
     * @method Phaser.Physics.Arcade#overlap
     * @param {Phaser.Sprite|Phaser.Group|Phaser.Particles.Emitter|array} object1 - The first object or array of objects to check. Can be Phaser.Sprite, Phaser.Group or Phaser.Particles.Emitter.
     * @param {Phaser.Sprite|Phaser.Group|Phaser.Particles.Emitter|array} object2 - The second object or array of objects to check. Can be Phaser.Sprite, Phaser.Group or Phaser.Particles.Emitter.
     * @param {function} [overlapCallback=null] - An optional callback function that is called if the objects overlap. The two objects will be passed to this function in the same order in which you specified them, unless you are checking Group vs. Sprite, in which case Sprite will always be the first parameter.
     * @param {function} [processCallback=null] - A callback function that lets you perform additional checks against the two objects if they overlap. If this is set then `overlapCallback` will only be called if this callback returns `true`.
     * @param {object} [callbackContext] - The context in which to run the callbacks.
     * @return {boolean} True if an overlap occurred otherwise false.
     */
    public function overlap(body1:Body, body2:Body, ?overlapCallback:Body->Body->Void, ?processCallback:Body->Body->Bool):Bool
    {

        _total = 0;

        if (separate(body1, body2, processCallback, true))
        {
            if (overlapCallback != null)
            {
                overlapCallback(body1, body2);
            }

            _total++;
        }

        return (_total > 0);

    } //overlap

    /**
     * Checks for collision between two game objects and separates them if colliding ({@link https://gist.github.com/samme/cbb81dd19f564dcfe2232761e575063d details}). If you don't require separation then use {@link #overlap} instead.
     *
     * You can perform Sprite vs. Sprite, Sprite vs. Group, Group vs. Group, Sprite vs. Tilemap Layer or Group vs. Tilemap Layer collisions.
     * Both the `object1` and `object2` can be arrays of objects, of differing types.
     *
     * If two Groups or arrays are passed, each member of one will be tested against each member of the other.
     *
     * If one Group **only** is passed (as `object1`), each member of the Group will be collided against the other members.
     *
     * If either object is `null` the collision test will fail.
     *
     * Bodies with `enable = false` and Sprites with `exists = false` are skipped (ignored).
     *
     * An optional processCallback can be provided. If given this function will be called when two sprites are found to be colliding. It is called before any separation takes place, giving you the chance to perform additional checks. If the function returns true then the collision and separation is carried out. If it returns false it is skipped.
     *
     * The collideCallback is an optional function that is only called if two sprites collide. If a processCallback has been set then it needs to return true for collideCallback to be called.
     *
     * **This function is not recursive**, and will not test against children of objects passed (i.e. Groups or Tilemaps within other Groups).
     *
     * ##### Examples
     *
     * ```javascript
     * collide(group);
     * collide(group, undefined); // equivalent
     *
     * collide(sprite1, sprite2);
     *
     * collide(sprite, group);
     *
     * collide(group1, group2);
     *
     * collide([sprite1, sprite2], [sprite3, sprite4]); // 1 vs. 3, 1 vs. 4, 2 vs. 3, 2 vs. 4
     * ```
     *
     * ##### Tilemaps
     *
     * Tiles marked via {@link Phaser.Tilemap#setCollision} (and similar methods) are "solid". If a Sprite collides with one of these tiles, the two are separated by moving the Sprite outside the tile's edges. Enable {@link Phaser.TilemapLayer#debug} to see the colliding edges of the Tilemap.
     *
     * Tiles with a callback attached via {@link Phaser.Tilemap#setTileIndexCallback} or {@link Phaser.Tilemap#setTileLocationCallback} invoke the callback if a Sprite collides with them. If a tile has a callback attached via both methods, only the location callback is invoked. The colliding Sprite is separated from the tile only if the callback returns `true`.
     *
     * @method Phaser.Physics.Arcade#collide
     * @param {Phaser.Sprite|Phaser.Group|Phaser.Particles.Emitter|Phaser.TilemapLayer|array} object1 - The first object or array of objects to check. Can be Phaser.Sprite, Phaser.Group, Phaser.Particles.Emitter, or Phaser.TilemapLayer.
     * @param {Phaser.Sprite|Phaser.Group|Phaser.Particles.Emitter|Phaser.TilemapLayer|array} object2 - The second object or array of objects to check. Can be Phaser.Sprite, Phaser.Group, Phaser.Particles.Emitter or Phaser.TilemapLayer.
     * @param {function} [collideCallback=null] - An optional callback function that is called if the objects collide. The two objects will be passed to this function in the same order in which you specified them, unless you are colliding Group vs. Sprite, in which case Sprite will always be the first parameter.
     * @param {function} [processCallback=null] - A callback function that lets you perform additional checks against the two objects if they overlap. If this is set then collision will only happen if processCallback returns true. The two objects will be passed to this function in the same order in which you specified them, unless you are colliding Group vs. Sprite, in which case Sprite will always be the first parameter.
     * @param {object} [callbackContext] - The context in which to run the callbacks.
     * @return {boolean} True if a collision occurred otherwise false.
     */
    public function collide(body1:Body, body2:Body, ?collideCallback:Body->Body->Void, ?processCallback:Body->Body->Bool):Bool
    {

        _total = 0;

        if (separate(body1, body2, processCallback, false))
        {
            if (collideCallback != null)
            {
                collideCallback(body1, body2);
            }

            _total++;
        }

        return (_total > 0);

    } //collide

    /**
     * This method will sort a Groups hash array.
     *
     * If the Group has `physicsSortDirection` set it will use the sort direction defined.
     *
     * Otherwise if the sortDirection parameter is undefined, or Group.physicsSortDirection is null, it will use Phaser.Physics.Arcade.sortDirection.
     *
     * By changing Group.physicsSortDirection you can customise each Group to sort in a different order.
     *
     * @method Phaser.Physics.Arcade#sort
     * @param {Phaser.Group} group - The Group to sort.
     * @param {integer} [sortDirection] - The sort direction used to sort this Group.
     */
    public function sort(group:Group, sortDirection:SortDirection = SortDirection.INHERIT)
    {

        if (group.sortDirection != SortDirection.INHERIT)
        {
            sortDirection = group.sortDirection;
        }
        else if (sortDirection == SortDirection.INHERIT)
        {
            sortDirection = this.sortDirection;
        }

        if (sortDirection == SortDirection.LEFT_RIGHT)
        {
            //  Game world is say 2000x600 and you start at 0
            group.sortLeftRight();
        }
        else if (sortDirection == SortDirection.RIGHT_LEFT)
        {
            //  Game world is say 2000x600 and you start at 2000
            group.sortRightLeft();
        }
        else if (sortDirection == SortDirection.TOP_BOTTOM)
        {
            //  Game world is say 800x2000 and you start at 0
            group.sortTopBottom();
        }
        else if (sortDirection == SortDirection.BOTTOM_TOP)
        {
            //  Game world is say 800x2000 and you start at 2000
            group.sortBottomTop();
        }

    } //sort

    /**
     * The core separation function to separate two physics bodies.
     *
     * @private
     * @method Phaser.Physics.Arcade#separate
     * @param {Phaser.Physics.Arcade.Body} body1 - The first Body object to separate.
     * @param {Phaser.Physics.Arcade.Body} body2 - The second Body object to separate.
     * @param {function} [processCallback=null] - A callback function that lets you perform additional checks against the two objects if they overlap. If this function is set then the sprites will only be collided if it returns true.
     * @param {object} [callbackContext] - The context in which to run the process callback.
     * @param {boolean} overlapOnly - Just run an overlap or a full collision.
     * @return {boolean} Returns true if the bodies collided, otherwise false.
     */
    private function separate(body1:Body, body2:Body, ?processCallback:Body->Body->Bool, overlapOnly:Bool):Bool
    {

        if (
            !body1.enable ||
            !body2.enable ||
            body1.checkCollisionNone ||
            body2.checkCollisionNone ||
            !this.intersects(body1, body2))
        {
            return false;
        }

        //  They overlap. Is there a custom process callback? If it returns true then we can carry on, otherwise we should abort.
        if (processCallback != null && processCallback(body1, body2) == false)
        {
            return false;
        }

        //  Circle vs. Circle quick bail out
        if (body1.isCircle && body2.isCircle)
        {
            return this.separateCircle(body1, body2, overlapOnly);
        }

        // We define the behavior of bodies in a collision circle and rectangle
        // If a collision occurs in the corner points of the rectangle, the body behave like circles

        //  Either body1 or body2 is a circle
        if (body1.isCircle != body2.isCircle)
        {
            var bodyRect = (body1.isCircle) ? body2 : body1;
            var bodyCircle = (body1.isCircle) ? body1 : body2;

            var rectLeft = bodyRect.left;
            var rectTop = bodyRect.top;
            var rectRight = bodyRect.right;
            var rectBottom = bodyRect.bottom;

            var circle = bodyCircle.center;

            if (circle.y < rectTop || circleY > rectBottom)
            {
                if (circle.x < rectLeft || circle.x > rectRight)
                {
                    return this.separateCircle(body1, body2, overlapOnly);
                }
            }
        }

        var resultX = false;
        var resultY = false;

        //  Do we separate on x or y first?
        if (this.forceX || Math.abs(this.gravityY + body1.gravityY) < Math.abs(this.gravityX + body1.gravityX))
        {
            resultX = this.separateX(body1, body2, overlapOnly);

            //  Are they still intersecting? Let's do the other axis then
            if (this.intersects(body1, body2))
            {
                resultY = this.separateY(body1, body2, overlapOnly);
            }
        }
        else
        {
            resultY = this.separateY(body1, body2, overlapOnly);

            //  Are they still intersecting? Let's do the other axis then
            if (this.intersects(body1, body2))
            {
                resultX = this.separateX(body1, body2, overlapOnly);
            }
        }

        var result = (resultX || resultY);

        if (result)
        {
            if (overlapOnly)
            {
                body1.emitOverlap(body1, body2);
                body2.emitOverlap(body2, body1);
            }
            else
            {
                body1.emitCollide(body1, body2);
                body2.emitCollide(body2, body1);
            }
        }

        return result;

    } //separate

    /**
     * Check for intersection against two bodies.
     *
     * @method Phaser.Physics.Arcade#intersects
     * @param {Phaser.Physics.Arcade.Body} body1 - The first Body object to check.
     * @param {Phaser.Physics.Arcade.Body} body2 - The second Body object to check.
     * @return {boolean} True if they intersect, otherwise false.
     */
    public function intersects(body1:Body, body2:Body):Bool
    {

        if (body1 == body2)
        {
            return false;
        }

        if (body1.isCircle)
        {
            if (body2.isCircle)
            {
                //  Circle vs. Circle
                return distance(body1.centerX, body1.centerY, body2.centerX, body2.centerY) <= (body1.halfWidth + body2.halfWidth);
            }
            else
            {
                //  Circle vs. Rect
                return this.circleBodyIntersects(body1, body2);
            }
        }
        else if (body2.isCircle)
        {
            //  Rect vs. Circle
            return this.circleBodyIntersects(body2, body1);
        }
        else
        {
            //  Rect vs. Rect
            if (body1.right <= body2.left)
            {
                return false;
            }

            if (body1.bottom <= body2.top)
            {
                return false;
            }

            if (body1.left >= body2.right)
            {
                return false;
            }

            if (body1.top >= body2.bottom)
            {
                return false;
            }

            return true;
        }

    } //intersects

    /**
     * Checks to see if a circular Body intersects with a Rectangular Body.
     *
     * @method Phaser.Physics.Arcade#circleBodyIntersects
     * @param {Phaser.Physics.Arcade.Body} circle - The Body with `isCircle` set.
     * @param {Phaser.Physics.Arcade.Body} body - The Body with `isCircle` not set (i.e. uses Rectangle shape)
     * @return {boolean} Returns true if the bodies intersect, otherwise false.
     */
    function circleBodyIntersects(circle:Body, body:Body):Bool
    {

        var x = clamp(circle.centerX, body.left, body.right);
        var y = clamp(circle.centerY, body.top, body.bottom);

        var dx = (circle.centerX - x) * (circle.centerX - x);
        var dy = (circle.centerY - y) * (circle.centerY - y);

        return (dx + dy) <= (circle.halfWidth * circle.halfWidth);

    } //circleBodyIntersects

    /**
     * The core separation function to separate two circular physics bodies.
     *
     * @method Phaser.Physics.Arcade#separateCircle
     * @private
     * @param {Phaser.Physics.Arcade.Body} body1 - The first Body to separate. Must have `Body.isCircle` true and a positive `radius`.
     * @param {Phaser.Physics.Arcade.Body} body2 - The second Body to separate. Must have `Body.isCircle` true and a positive `radius`.
     * @param {boolean} overlapOnly - If true the bodies will only have their overlap data set, no separation or exchange of velocity will take place.
     * @return {boolean} Returns true if the bodies were separated or overlap, otherwise false.
     */
    function separateCircle(body1:Body, body2:Body, overlapOnly:Bool):Bool
    {

        //  Set the bounding box overlap values
        this.getOverlapX(body1, body2);
        this.getOverlapY(body1, body2);

        var dx = body2.centerX - body1.centerX;
        var dy = body2.centerY - body1.centerY;

        var angleCollision = Math.atan2(dy, dx);

        var overlap:Float = 0;

        if (body1.isCircle != body2.isCircle)
        {
            var rectLeft = (body2.isCircle) ? body1.left : body2.left;
            var rectTop = (body2.isCircle) ? body1.top : body2.top;
            var rectRight = (body2.isCircle) ? body1.right : body2.right;
            var rectBottom = (body2.isCircle) ? body1.bottom : body2.bottom;

            var circleX = (body1.isCircle) ? body1.centerX : body2.centerX;
            var circleY = (body1.isCircle) ? body1.centerY : body2.centerY;
            var circleRadius = (body1.isCircle) ? body1.halfWidth : body2.halfWidth;

            if (circleY < rectTop)
            {
                if (circleX < rectLeft)
                {
                    overlap = distance(circleX, circleY, rectLeft, rectTop) - circleRadius;
                }
                else if (circleX > rectRight)
                {
                    overlap = distance(circleX, circleY, rectRight, rectTop) - circleRadius;
                }
            }
            else if (circleY > rectBottom)
            {
                if (circleX < rectLeft)
                {
                    overlap = distance(circleX, circleY, rectLeft, rectBottom) - circleRadius;
                }
                else if (circleX > rectRight)
                {
                    overlap = distance(circleX, circleY, rectRight, rectBottom) - circleRadius;
                }
            }

            overlap *= -1;
        }
        else
        {
            overlap = (body1.halfWidth + body2.halfWidth) - distance(body1.centerX, body1.centerY, body2.centerX, body2.centerY);
        }

        //  Can't separate two immovable bodies, or a body with its own custom separation logic
        if (overlapOnly || overlap == 0 || (body1.immovable && body2.immovable) || body1.customSeparateX || body2.customSeparateX)
        {
            if (overlap != 0)
            {
                body1.emitOverlap(body1, body2);
                body2.emitOverlap(body2, body1);
            }

            //  return true if there was some overlap, otherwise false
            return (overlap != 0);
        }

        // Transform the velocity vector to the coordinate system oriented along the direction of impact.
        // This is done to eliminate the vertical component of the velocity
        var v1X = body1.velocityX * Math.cos(angleCollision) + body1.velocityY * Math.sin(angleCollision);
        var v1Y = -body1.velocityX * Math.sin(angleCollision) + body1.velocityY * Math.cos(angleCollision);

        var v2X = body2.velocityX * Math.cos(angleCollision) + body2.velocityY * Math.sin(angleCollision);
        var v2Y = -body2.velocityX * Math.sin(angleCollision) + body2.velocityY * Math.cos(angleCollision);

        // We expect the new velocity after impact
        var tempVel1 = ((body1.mass - body2.mass) * v1X + 2 * body2.mass * v2X) / (body1.mass + body2.mass);
        var tempVel2 = (2 * body1.mass * v1X + (body2.mass - body1.mass) * v2X) / (body1.mass + body2.mass);

        // We convert the vector to the original coordinate system and multiplied by factor of rebound
        if (!body1.immovable)
        {
            body1.velocityX = (tempVel1 * Math.cos(angleCollision) - v1Y * Math.sin(angleCollision)) * body1.bounceX;
            body1.velocityY = (v1Y * Math.cos(angleCollision) + tempVel1 * Math.sin(angleCollision)) * body1.bounceY;
        }

        if (!body2.immovable)
        {
            body2.velocityX = (tempVel2 * Math.cos(angleCollision) - v2Y * Math.sin(angleCollision)) * body2.bounceX;
            body2.velocityY = (v2Y * Math.cos(angleCollision) + tempVel2 * Math.sin(angleCollision)) * body2.bounceY;
        }

        // When the collision angle is almost perpendicular to the total initial velocity vector
        // (collision on a tangent) vector direction can be determined incorrectly.
        // This code fixes the problem

        if (Math.abs(angleCollision) < HALF_PI)
        {
            if ((body1.velocityX > 0) && !body1.immovable && (body2.velocityX > body1.velocityX))
            {
                body1.velocityX *= -1;
            }
            else if ((body2.velocityX < 0) && !body2.immovable && (body1.velocityX < body2.velocityX))
            {
                body2.velocityX *= -1;
            }
            else if ((body1.velocityY > 0) && !body1.immovable && (body2.velocityY > body1.velocityY))
            {
                body1.velocityY *= -1;
            }
            else if ((body2.velocityY < 0) && !body2.immovable && (body1.velocityY < body2.velocityY))
            {
                body2.velocityY *= -1;
            }
        }
        else if (Math.abs(angleCollision) > HALF_PI)
        {
            if ((body1.velocityX < 0) && !body1.immovable && (body2.velocityX < body1.velocityX))
            {
                body1.velocityX *= -1;
            }
            else if ((body2.velocityX > 0) && !body2.immovable && (body1.velocityX > body2.velocityX))
            {
                body2.velocityX *= -1;
            }
            else if ((body1.velocityY < 0) && !body1.immovable && (body2.velocityY < body1.velocityY))
            {
                body1.velocityY *= -1;
            }
            else if ((body2.velocityY > 0) && !body2.immovable && (body1.velocityX > body2.velocityY))
            {
                body2.velocityY *= -1;
            }
        }

        if (!body1.immovable)
        {
            body1.x += (body1.velocityX * elapsed) - overlap * Math.cos(angleCollision);
            body1.y += (body1.velocityY * elapsed) - overlap * Math.sin(angleCollision);
        }

        if (!body2.immovable)
        {
            body2.x += (body2.velocityX * elapsed) + overlap * Math.cos(angleCollision);
            body2.y += (body2.velocityY * elapsed) + overlap * Math.sin(angleCollision);
        }

        body1.emitCollide(body1, body2);
        body2.emitCollide(body2, body1);

        return true;

    } //separateCircle

    /**
     * Calculates the horizontal overlap between two Bodies and sets their properties accordingly, including:
     * `touchingLeft`, `touchingRight` and `overlapX`.
     *
     * @method Phaser.Physics.Arcade#getOverlapX
     * @param {Phaser.Physics.Arcade.Body} body1 - The first Body to separate.
     * @param {Phaser.Physics.Arcade.Body} body2 - The second Body to separate.
     * @param {boolean} overlapOnly - Is this an overlap only check, or part of separation?
     * @return {float} Returns the amount of horizontal overlap between the two bodies.
     */
    function getOverlapX(body1:Body, body2:Body, overlapOnly:Bool):Bool
    {

        var overlap = 0;
        var maxOverlap = body1.deltaAbsX() + body2.deltaAbsX() + this.overlapBias;

        if (body1.deltaX() == 0 && body2.deltaX() == 0)
        {
            //  They overlap but neither of them are moving
            body1.embedded = true;
            body2.embedded = true;
        }
        else if (body1.deltaX() > body2.deltaX())
        {
            //  Body1 is moving right and / or Body2 is moving left
            overlap = body1.right - body2.x;

            if ((overlap > maxOverlap && !overlapOnly) || body1.checkCollisionRight == false || body2.checkCollisionLeft == false)
            {
                overlap = 0;
            }
            else
            {
                body1.touchingNone = false;
                body1.touchingRight = true;
                body2.touchingNone = false;
                body2.touchingLeft = true;
            }
        }
        else if (body1.deltaX() < body2.deltaX())
        {
            //  Body1 is moving left and/or Body2 is moving right
            overlap = body1.x - body2.width - body2.x;

            if ((-overlap > maxOverlap && !overlapOnly) || body1.checkCollisionLeft == false || body2.checkCollisionRight == false)
            {
                overlap = 0;
            }
            else
            {
                body1.touchingNone = false;
                body1.touchingLeft = true;
                body2.touchingNone = false;
                body2.touchingRight = true;
            }
        }

        //  Resets the overlapX to zero if there is no overlap, or to the actual pixel value if there is
        body1.overlapX = overlap;
        body2.overlapX = overlap;

        return overlap;

    } //getOverlapX

    /**
     * Calculates the vertical overlap between two Bodies and sets their properties accordingly, including:
     * `touchingUp`, `touchingDown` and `overlapY`.
     *
     * @method Phaser.Physics.Arcade#getOverlapY
     * @param {Phaser.Physics.Arcade.Body} body1 - The first Body to separate.
     * @param {Phaser.Physics.Arcade.Body} body2 - The second Body to separate.
     * @param {boolean} overlapOnly - Is this an overlap only check, or part of separation?
     * @return {float} Returns the amount of vertical overlap between the two bodies.
     */
    function getOverlapY(body1:Body, body2:Body, overlapOnly:Bool):Bool
    {

        var overlap = 0;
        var maxOverlap = body1.deltaAbsY() + body2.deltaAbsY() + this.overlapBias;

        if (body1.deltaY() == 0 && body2.deltaY() == 0)
        {
            //  They overlap but neither of them are moving
            body1.embedded = true;
            body2.embedded = true;
        }
        else if (body1.deltaY() > body2.deltaY())
        {
            //  Body1 is moving down and/or Body2 is moving up
            overlap = body1.bottom - body2.y;

            if ((overlap > maxOverlap && !overlapOnly) || body1.checkCollisionDown == false || body2.checkCollisionUp == false)
            {
                overlap = 0;
            }
            else
            {
                body1.touchingNone = false;
                body1.touchingDown = true;
                body2.touchingNone = false;
                body2.touchingUp = true;
            }
        }
        else if (body1.deltaY() < body2.deltaY())
        {
            //  Body1 is moving up and/or Body2 is moving down
            overlap = body1.y - body2.bottom;

            if ((-overlap > maxOverlap && !overlapOnly) || body1.checkCollisionUp == false || body2.checkCollisionDown == false)
            {
                overlap = 0;
            }
            else
            {
                body1.touchingNone = false;
                body1.touchingUp = true;
                body2.touchingNone = false;
                body2.touchingDown = true;
            }
        }

        //  Resets the overlapY to zero if there is no overlap, or to the actual pixel value if there is
        body1.overlapY = overlap;
        body2.overlapY = overlap;

        return overlap;

    } //getOverlapY

    /**
     * The core separation function to separate two physics bodies on the x axis.
     *
     * @method Phaser.Physics.Arcade#separateX
     * @private
     * @param {Phaser.Physics.Arcade.Body} body1 - The first Body to separate.
     * @param {Phaser.Physics.Arcade.Body} body2 - The second Body to separate.
     * @param {boolean} overlapOnly - If true the bodies will only have their overlap data set, no separation or exchange of velocity will take place.
     * @return {boolean} Returns true if the bodies were separated or overlap, otherwise false.
     */
    function separateX(body1:Body, body2:Body, overlapOnly:Bool):Bool
    {

        var overlap = this.getOverlapX(body1, body2, overlapOnly);

        //  Can't separate two immovable bodies, or a body with its own custom separation logic
        if (overlapOnly || overlap == 0 || (body1.immovable && body2.immovable) || body1.customSeparateX || body2.customSeparateX)
        {
            //  return true if there was some overlap, otherwise false
            return (overlap != 0) || (body1.embedded && body2.embedded);
        }

        //  Adjust their positions and velocities accordingly (if there was any overlap)
        var v1 = body1.velocityX;
        var v2 = body2.velocityX;

        if (!body1.immovable && !body2.immovable)
        {
            overlap *= 0.5;

            body1.x -= overlap;
            body2.x += overlap;

            var nv1 = Math.sqrt((v2 * v2 * body2.mass) / body1.mass) * ((v2 > 0) ? 1 : -1);
            var nv2 = Math.sqrt((v1 * v1 * body1.mass) / body2.mass) * ((v1 > 0) ? 1 : -1);
            var avg = (nv1 + nv2) * 0.5;

            nv1 -= avg;
            nv2 -= avg;

            body1.velocityX = avg + nv1 * body1.bounceX;
            body2.velocityX = avg + nv2 * body2.bounceX;
        }
        else if (!body1.immovable)
        {
            body1.x -= overlap;
            body1.velocityX = v2 - v1 * body1.bounceX;

            //  This is special case code that handles things like vertically moving platforms you can ride
            if (body2.moves)
            {
                body1.y += (body2.y - body2.prev.y) * body2.friction.y;
            }
        }
        else
        {
            body2.x += overlap;
            body2.velocityX = v1 - v2 * body2.bounceX;

            //  This is special case code that handles things like vertically moving platforms you can ride
            if (body1.moves)
            {
                body2.y += (body1.y - body1.prev.y) * body1.friction.y;
            }
        }

        //  If we got this far then there WAS overlap, and separation is complete, so return true
        return true;

    } //separateX

    /**
     * The core separation function to separate two physics bodies on the y axis.
     *
     * @private
     * @method Phaser.Physics.Arcade#separateY
     * @param {Phaser.Physics.Arcade.Body} body1 - The first Body to separate.
     * @param {Phaser.Physics.Arcade.Body} body2 - The second Body to separate.
     * @param {boolean} overlapOnly - If true the bodies will only have their overlap data set, no separation or exchange of velocity will take place.
     * @return {boolean} Returns true if the bodies were separated or overlap, otherwise false.
     */
    function separateY(body1:Body, body2:Body, overlapOnly:Bool):Bool
    {

        var overlap = this.getOverlapY(body1, body2, overlapOnly);

        //  Can't separate two immovable bodies, or a body with its own custom separation logic
        if (overlapOnly || overlap == 0 || (body1.immovable && body2.immovable) || body1.customSeparateY || body2.customSeparateY)
        {
            //  return true if there was some overlap, otherwise false
            return (overlap != 0) || (body1.embedded && body2.embedded);
        }

        //  Adjust their positions and velocities accordingly (if there was any overlap)
        var v1 = body1.velocityY;
        var v2 = body2.velocityY;

        if (!body1.immovable && !body2.immovable)
        {
            overlap *= 0.5;

            body1.y -= overlap;
            body2.y += overlap;

            var nv1 = Math.sqrt((v2 * v2 * body2.mass) / body1.mass) * ((v2 > 0) ? 1 : -1);
            var nv2 = Math.sqrt((v1 * v1 * body1.mass) / body2.mass) * ((v1 > 0) ? 1 : -1);
            var avg = (nv1 + nv2) * 0.5;

            nv1 -= avg;
            nv2 -= avg;

            body1.velocityY = avg + nv1 * body1.bounceY;
            body2.velocityY = avg + nv2 * body2.bounceY;
        }
        else if (!body1.immovable)
        {
            body1.y -= overlap;
            body1.velocityY = v2 - v1 * body1.bounceY;

            //  This is special case code that handles things like horizontal moving platforms you can ride
            if (body2.moves)
            {
                body1.x += (body2.x - body2.prev.x) * body2.friction.x;
            }
        }
        else
        {
            body2.y += overlap;
            body2.velocityY = v1 - v2 * body2.bounceY;

            //  This is special case code that handles things like horizontal moving platforms you can ride
            if (body1.moves)
            {
                body2.x += (body1.x - body1.prev.x) * body1.friction.x;
            }
        }

        //  If we got this far then there WAS overlap, and separation is complete, so return true
        return true;

    } //separateY

    /**
     * Given a Group and a Pointer this will check to see which Group children overlap with the Pointer coordinates.
     * Each child will be sent to the given callback for further processing.
     * Note that the children are not checked for depth order, but simply if they overlap the Pointer or not.
     *
     * @method Phaser.Physics.Arcade#getObjectsUnderPointer
     * @param {Phaser.Pointer} pointer - The Pointer to check.
     * @param {Phaser.Group} group - The Group to check.
     * @param {function} [callback] - A callback function that is called if the object overlaps with the Pointer. The callback will be sent two parameters: the Pointer and the Object that overlapped with it.
     * @param {object} [callbackContext] - The context in which to run the callback.
     * @return {PIXI.DisplayObject[]} An array of the Sprites from the Group that overlapped the Pointer coordinates.
     */
    getObjectsUnderPointer: function (pointer, group, callback, callbackContext)
    {

        if (group.length === 0 || !pointer.exists)
        {
            return;
        }

        return this.getObjectsAtLocation(pointer.x, pointer.y, group, callback, callbackContext, pointer);

    },

    /**
     * Given a Group and a location this will check to see which Group children overlap with the coordinates.
     * Each child will be sent to the given callback for further processing.
     * Note that the children are not checked for depth order, but simply if they overlap the coordinate or not.
     *
     * @method Phaser.Physics.Arcade#getObjectsAtLocation
     * @param {number} x - The x coordinate to check.
     * @param {number} y - The y coordinate to check.
     * @param {Phaser.Group} group - The Group to check.
     * @param {function} [callback] - A callback function that is called if the object overlaps the coordinates. The callback will be sent two parameters: the callbackArg and the Object that overlapped the location.
     * @param {object} [callbackContext] - The context in which to run the callback.
     * @param {object} [callbackArg] - An argument to pass to the callback.
     * @return {PIXI.DisplayObject[]} An array of the Sprites from the Group that overlapped the coordinates.
     */
    getObjectsAtLocation: function (x, y, group, callback, callbackContext, callbackArg)
    {

        this.quadTree.clear();

        this.quadTree.reset(this.game.world.bounds.x, this.game.world.bounds.y, this.game.world.bounds.width, this.game.world.bounds.height, this.maxObjects, this.maxLevels);

        this.quadTree.populate(group);

        var rect = new Phaser.Rectangle(x, y, 1, 1);
        var output = [];

        var items = this.quadTree.retrieve(rect);

        for (var i = 0; i < items.length; i++)
        {
            if (items[i].hitTest(x, y))
            {
                if (callback)
                {
                    callback.call(callbackContext, callbackArg, items[i].sprite);
                }

                output.push(items[i].sprite);
            }
        }

        return output;

    },

    /**
     * Move the given display object towards the destination object at a steady velocity.
     * If you specify a maxTime then it will adjust the speed (overwriting what you set) so it arrives at the destination in that number of seconds.
     * Timings are approximate due to the way browser timers work. Allow for a variance of +- 50ms.
     * Note: The display object does not continuously track the target. If the target changes location during transit the display object will not modify its course.
     * Note: The display object doesn't stop moving once it reaches the destination coordinates.
     * Note: Doesn't take into account acceleration, maxVelocity or drag (if you've set drag or acceleration too high this object may not move at all)
     *
     * @method Phaser.Physics.Arcade#moveToObject
     * @param {any} displayObject - The display object to move.
     * @param {any} destination - The display object to move towards. Can be any object but must have visible x/y properties.
     * @param {number} [speed=60] - The speed it will move, in pixels per second (default is 60 pixels/sec)
     * @param {number} [maxTime=0] - Time given in milliseconds (1000 = 1 sec). If set the speed is adjusted so the object will arrive at destination in the given number of ms.
     * @return {number} The angle (in radians) that the object should be visually set to in order to match its new velocity.
     */
    moveToObject: function (displayObject, destination, speed, maxTime)
    {

        if (speed === undefined) { speed = 60; }
        if (maxTime === undefined) { maxTime = 0; }

        var angle = Phaser.Point.angle(destination, displayObject);

        if (maxTime > 0)
        {
            //  We know how many pixels we need to move, but how fast?
            speed = this.distanceBetween(displayObject, destination) / (maxTime / 1000);
        }

        displayObject.body.velocity.setToPolar(angle, speed);

        return angle;

    },

    /**
     * Move the given display object towards the pointer at a steady velocity. If no pointer is given it will use Phaser.Input.activePointer.
     * If you specify a maxTime then it will adjust the speed (over-writing what you set) so it arrives at the destination in that number of seconds.
     * Timings are approximate due to the way browser timers work. Allow for a variance of +- 50ms.
     * Note: The display object does not continuously track the target. If the target changes location during transit the display object will not modify its course.
     * Note: The display object doesn't stop moving once it reaches the destination coordinates.
     *
     * @method Phaser.Physics.Arcade#moveToPointer
     * @param {any} displayObject - The display object to move.
     * @param {number} [speed=60] - The speed it will move, in pixels per second (default is 60 pixels/sec)
     * @param {Phaser.Pointer} [pointer] - The pointer to move towards. Defaults to Phaser.Input.activePointer.
     * @param {number} [maxTime=0] - Time given in milliseconds (1000 = 1 sec). If set the speed is adjusted so the object will arrive at destination in the given number of ms.
     * @return {number} The angle (in radians) that the object should be visually set to in order to match its new velocity.
     */
    moveToPointer: function (displayObject, speed, pointer, maxTime)
    {

        if (speed === undefined) { speed = 60; }
        pointer = pointer || this.game.input.activePointer;
        if (maxTime === undefined) { maxTime = 0; }

        var angle = this.angleToPointer(displayObject, pointer);

        if (maxTime > 0)
        {
            //  We know how many pixels we need to move, but how fast?
            speed = this.distanceToPointer(displayObject, pointer) / (maxTime / 1000);
        }

        displayObject.body.velocity.setToPolar(angle, speed);

        return angle;

    },

    /**
     * Move the given display object towards the x/y coordinates at a steady velocity.
     * If you specify a maxTime then it will adjust the speed (over-writing what you set) so it arrives at the destination in that number of seconds.
     * Timings are approximate due to the way browser timers work. Allow for a variance of +- 50ms.
     * Note: The display object does not continuously track the target. If the target changes location during transit the display object will not modify its course.
     * Note: The display object doesn't stop moving once it reaches the destination coordinates.
     * Note: Doesn't take into account acceleration, maxVelocity or drag (if you've set drag or acceleration too high this object may not move at all)
     *
     * @method Phaser.Physics.Arcade#moveToXY
     * @param {any} displayObject - The display object to move.
     * @param {number} x - The x coordinate to move towards.
     * @param {number} y - The y coordinate to move towards.
     * @param {number} [speed=60] - The speed it will move, in pixels per second (default is 60 pixels/sec)
     * @param {number} [maxTime=0] - Time given in milliseconds (1000 = 1 sec). If set the speed is adjusted so the object will arrive at destination in the given number of ms.
     * @return {number} The angle (in radians) that the object should be visually set to in order to match its new velocity.
     */
    moveToXY: function (displayObject, x, y, speed, maxTime)
    {

        if (speed === undefined) { speed = 60; }
        if (maxTime === undefined) { maxTime = 0; }

        var angle = Math.atan2(y - displayObject.y, x - displayObject.x);

        if (maxTime > 0)
        {
            //  We know how many pixels we need to move, but how fast?
            speed = this.distanceToXY(displayObject, x, y) / (maxTime / 1000);
        }

        displayObject.body.velocity.setToPolar(angle, speed);

        return angle;

    },

    /**
     * Given the angle (in degrees) and speed calculate the velocity and return it as a Point object, or set it to the given point object.
     * One way to use this is: velocityFromAngle(angle, 200, sprite.velocity) which will set the values directly to the sprites velocity and not create a new Point object.
     *
     * @method Phaser.Physics.Arcade#velocityFromAngle
     * @param {number} angle - The angle in degrees calculated in clockwise positive direction (down = 90 degrees positive, right = 0 degrees positive, up = 90 degrees negative)
     * @param {number} [speed=60] - The speed it will move, in pixels per second sq.
     * @param {Phaser.Point|object} [point] - The Point object in which the x and y properties will be set to the calculated velocity.
     * @return {Phaser.Point} - A Point where point.x contains the velocity x value and point.y contains the velocity y value.
     */
    velocityFromAngle: function (angle, speed, point)
    {

        if (speed === undefined) { speed = 60; }
        point = point || new Phaser.Point();

        return point.setToPolar(angle, speed, true);

    },

    /**
     * Given the rotation (in radians) and speed calculate the velocity and return it as a Point object, or set it to the given point object.
     * One way to use this is: velocityFromRotation(rotation, 200, sprite.velocity) which will set the values directly to the sprites velocity and not create a new Point object.
     *
     * @method Phaser.Physics.Arcade#velocityFromRotation
     * @param {number} rotation - The angle in radians.
     * @param {number} [speed=60] - The speed it will move, in pixels per second sq.
     * @param {Phaser.Point|object} [point] - The Point object in which the x and y properties will be set to the calculated velocity.
     * @return {Phaser.Point} - A Point where point.x contains the velocity x value and point.y contains the velocity y value.
     */
    velocityFromRotation: function (rotation, speed, point)
    {

        if (speed === undefined) { speed = 60; }
        point = point || new Phaser.Point();

        return point.setToPolar(rotation, speed);

    },

    /**
     * Given the rotation (in radians) and speed calculate the acceleration and return it as a Point object, or set it to the given point object.
     * One way to use this is: accelerationFromRotation(rotation, 200, sprite.acceleration) which will set the values directly to the sprites acceleration and not create a new Point object.
     *
     * @method Phaser.Physics.Arcade#accelerationFromRotation
     * @param {number} rotation - The angle in radians.
     * @param {number} [speed=60] - The speed it will move, in pixels per second sq.
     * @param {Phaser.Point|object} [point] - The Point object in which the x and y properties will be set to the calculated acceleration.
     * @return {Phaser.Point} - A Point where point.x contains the acceleration x value and point.y contains the acceleration y value.
     */
    accelerationFromRotation: function (rotation, speed, point)
    {

        if (speed === undefined) { speed = 60; }
        point = point || new Phaser.Point();

        return point.setToPolar(rotation, speed);

    },

    /**
     * Sets the acceleration.x/y property on the display object so it will move towards the target at the given speed (in pixels per second sq.)
     * You must give a maximum speed value, beyond which the display object won't go any faster.
     * Note: The display object does not continuously track the target. If the target changes location during transit the display object will not modify its course.
     * Note: The display object doesn't stop moving once it reaches the destination coordinates.
     *
     * @method Phaser.Physics.Arcade#accelerateToObject
     * @param {any} displayObject - The display object to move.
     * @param {any} destination - The display object to move towards. Can be any object but must have visible x/y properties.
     * @param {number} [speed=60] - The speed it will accelerate in pixels per second.
     * @param {number} [xSpeedMax=500] - The maximum x velocity the display object can reach.
     * @param {number} [ySpeedMax=500] - The maximum y velocity the display object can reach.
     * @return {number} The angle (in radians) that the object should be visually set to in order to match its new trajectory.
     */
    accelerateToObject: function (displayObject, destination, speed, xSpeedMax, ySpeedMax)
    {

        if (speed === undefined) { speed = 60; }
        if (xSpeedMax === undefined) { xSpeedMax = 1000; }
        if (ySpeedMax === undefined) { ySpeedMax = 1000; }

        var angle = this.angleBetween(displayObject, destination);

        displayObject.body.acceleration.setToPolar(angle, speed);
        displayObject.body.maxVelocity.setTo(xSpeedMax, ySpeedMax);

        return angle;

    },

    /**
     * Sets the acceleration.x/y property on the display object so it will move towards the target at the given speed (in pixels per second sq.)
     * You must give a maximum speed value, beyond which the display object won't go any faster.
     * Note: The display object does not continuously track the target. If the target changes location during transit the display object will not modify its course.
     * Note: The display object doesn't stop moving once it reaches the destination coordinates.
     *
     * @method Phaser.Physics.Arcade#accelerateToPointer
     * @param {any} displayObject - The display object to move.
     * @param {Phaser.Pointer} [pointer] - The pointer to move towards. Defaults to Phaser.Input.activePointer.
     * @param {number} [speed=60] - The speed it will accelerate in pixels per second.
     * @param {number} [xSpeedMax=500] - The maximum x velocity the display object can reach.
     * @param {number} [ySpeedMax=500] - The maximum y velocity the display object can reach.
     * @return {number} The angle (in radians) that the object should be visually set to in order to match its new trajectory.
     */
    accelerateToPointer: function (displayObject, pointer, speed, xSpeedMax, ySpeedMax)
    {

        if (speed === undefined) { speed = 60; }
        if (pointer === undefined) { pointer = this.game.input.activePointer; }
        if (xSpeedMax === undefined) { xSpeedMax = 1000; }
        if (ySpeedMax === undefined) { ySpeedMax = 1000; }

        var angle = this.angleToPointer(displayObject, pointer);

        displayObject.body.acceleration.setToPolar(angle, speed);
        displayObject.body.maxVelocity.setTo(xSpeedMax, ySpeedMax);

        return angle;

    },

    /**
     * Sets the acceleration.x/y property on the display object so it will move towards the x/y coordinates at the given speed (in pixels per second sq.)
     * You must give a maximum speed value, beyond which the display object won't go any faster.
     * Note: The display object does not continuously track the target. If the target changes location during transit the display object will not modify its course.
     * Note: The display object doesn't stop moving once it reaches the destination coordinates.
     *
     * @method Phaser.Physics.Arcade#accelerateToXY
     * @param {any} displayObject - The display object to move.
     * @param {number} x - The x coordinate to accelerate towards.
     * @param {number} y - The y coordinate to accelerate towards.
     * @param {number} [speed=60] - The speed it will accelerate in pixels per second.
     * @param {number} [xSpeedMax=500] - The maximum x velocity the display object can reach.
     * @param {number} [ySpeedMax=500] - The maximum y velocity the display object can reach.
     * @return {number} The angle (in radians) that the object should be visually set to in order to match its new trajectory.
     */
    accelerateToXY: function (displayObject, x, y, speed, xSpeedMax, ySpeedMax)
    {

        if (speed === undefined) { speed = 60; }
        if (xSpeedMax === undefined) { xSpeedMax = 1000; }
        if (ySpeedMax === undefined) { ySpeedMax = 1000; }

        var angle = this.angleToXY(displayObject, x, y);

        displayObject.body.acceleration.setTo(angle, speed);
        displayObject.body.maxVelocity.setTo(xSpeedMax, ySpeedMax);

        return angle;

    },

    /**
     * Find the distance between two display objects (like Sprites).
     *
     * The optional `world` argument allows you to return the result based on the Game Objects `world` property,
     * instead of its `x` and `y` values. This is useful of the object has been nested inside an offset Group,
     * or parent Game Object.
     *
     * If you have nested objects and need to calculate the distance between their centers in World coordinates,
     * set their anchors to (0.5, 0.5) and use the `world` argument.
     *
     * If objects aren't nested or they share a parent's offset, you can calculate the distance between their
     * centers with the `useCenter` argument, regardless of their anchor values.
     *
     * @method Phaser.Physics.Arcade#distanceBetween
     * @param {any} source - The Display Object to test from.
     * @param {any} target - The Display Object to test to.
     * @param {boolean} [world=false] - Calculate the distance using World coordinates (true), or Object coordinates (false, the default). If `useCenter` is true, this value is ignored.
     * @param {boolean} [useCenter=false] - Calculate the distance using the {@link Phaser.Sprite#centerX} and {@link Phaser.Sprite#centerY} coordinates. If true, this value overrides the `world` argument.
     * @return {number} The distance between the source and target objects.
     */
    distanceBetween: function (source, target, world, useCenter)
    {

        if (world === undefined) { world = false; }

        var dx;
        var dy;

        if (useCenter)
        {
            dx = source.centerX - target.centerX;
            dy = source.centerY - target.centerY;
        }
        else if (world)
        {
            dx = source.world.x - target.world.x;
            dy = source.world.y - target.world.y;
        }
        else
        {
            dx = source.x - target.x;
            dy = source.y - target.y;
        }

        return Math.sqrt(dx * dx + dy * dy);

    },

    /**
     * Find the distance between a display object (like a Sprite) and the given x/y coordinates.
     * The calculation is made from the display objects x/y coordinate. This may be the top-left if its anchor hasn't been changed.
     * If you need to calculate from the center of a display object instead use {@link #distanceBetween} with the `useCenter` argument.
     *
     * The optional `world` argument allows you to return the result based on the Game Objects `world` property,
     * instead of its `x` and `y` values. This is useful of the object has been nested inside an offset Group,
     * or parent Game Object.
     *
     * @method Phaser.Physics.Arcade#distanceToXY
     * @param {any} displayObject - The Display Object to test from.
     * @param {number} x - The x coordinate to move towards.
     * @param {number} y - The y coordinate to move towards.
     * @param {boolean} [world=false] - Calculate the distance using World coordinates (true), or Object coordinates (false, the default)
     * @return {number} The distance between the object and the x/y coordinates.
     */
    distanceToXY: function (displayObject, x, y, world)
    {

        if (world === undefined) { world = false; }

        var dx = (world) ? displayObject.world.x - x : displayObject.x - x;
        var dy = (world) ? displayObject.world.y - y : displayObject.y - y;

        return Math.sqrt(dx * dx + dy * dy);

    },

    /**
     * Find the distance between a display object (like a Sprite) and a Pointer. If no Pointer is given the Input.activePointer is used.
     * The calculation is made from the display objects x/y coordinate. This may be the top-left if its anchor hasn't been changed.
     * If you need to calculate from the center of a display object instead use {@link #distanceBetween} with the `useCenter` argument.
     *
     * The optional `world` argument allows you to return the result based on the Game Objects `world` property,
     * instead of its `x` and `y` values. This is useful of the object has been nested inside an offset Group,
     * or parent Game Object.
     *
     * @method Phaser.Physics.Arcade#distanceToPointer
     * @param {any} displayObject - The Display Object to test from.
     * @param {Phaser.Pointer} [pointer] - The Phaser.Pointer to test to. If none is given then Input.activePointer is used.
     * @param {boolean} [world=false] - Calculate the distance using World coordinates (true), or Object coordinates (false, the default)
     * @return {number} The distance between the object and the Pointer.
     */
    distanceToPointer: function (displayObject, pointer, world)
    {

        if (pointer === undefined) { pointer = this.game.input.activePointer; }
        if (world === undefined) { world = false; }

        var dx = (world) ? displayObject.world.x - pointer.worldX : displayObject.x - pointer.worldX;
        var dy = (world) ? displayObject.world.y - pointer.worldY : displayObject.y - pointer.worldY;

        return Math.sqrt(dx * dx + dy * dy);

    },


    /**
     * From a set of points or display objects, find the one closest to a source point or object.
     *
     * @method Phaser.Physics.Arcade#closest
     * @param {any} source - The {@link Phaser.Point Point} or Display Object distances will be measured from.
     * @param {any[]} targets - The {@link Phaser.Point Points} or Display Objects whose distances to the source will be compared.
     * @param {boolean} [world=false] - Calculate the distance using World coordinates (true), or Object coordinates (false, the default). If `useCenter` is true, this value is ignored.
     * @param {boolean} [useCenter=false] - Calculate the distance using the {@link Phaser.Sprite#centerX} and {@link Phaser.Sprite#centerY} coordinates. If true, this value overrides the `world` argument.
     * @return {any} - The first target closest to the origin.
     */
    closest: function (source, targets, world, useCenter)
    {
        var min = Infinity;
        var closest = null;

        for (var i = 0, len = targets.length; i < len; i++)
        {
            var target = targets[i];
            var distance = this.distanceBetween(source, target, world, useCenter);

            if (distance < min)
            {
                closest = target;
                min = distance;
            }
        }

        return closest;
    },

    /**
     * From a set of points or display objects, find the one farthest from a source point or object.
     *
     * @method Phaser.Physics.Arcade#farthest
     * @param {any} source - The {@link Phaser.Point Point} or Display Object distances will be measured from.
     * @param {any[]} targets - The {@link Phaser.Point Points} or Display Objects whose distances to the source will be compared.
     * @param {boolean} [world=false] - Calculate the distance using World coordinates (true), or Object coordinates (false, the default). If `useCenter` is true, this value is ignored.
     * @param {boolean} [useCenter=false] - Calculate the distance using the {@link Phaser.Sprite#centerX} and {@link Phaser.Sprite#centerY} coordinates. If true, this value overrides the `world` argument.
     * @return {any} - The target closest to the origin.
     */
    farthest: function (source, targets, world, useCenter)
    {
        var max = -1;
        var farthest = null;

        for (var i = 0, len = targets.length; i < len; i++)
        {
            var target = targets[i];
            var distance = this.distanceBetween(source, target, world, useCenter);

            if (distance > max)
            {
                farthest = target;
                max = distance;
            }
        }

        return farthest;
    },

    /**
     * Find the angle in radians between two display objects (like Sprites).
     *
     * The optional `world` argument allows you to return the result based on the Game Objects `world` property,
     * instead of its `x` and `y` values. This is useful of the object has been nested inside an offset Group,
     * or parent Game Object.
     *
     * @method Phaser.Physics.Arcade#angleBetween
     * @param {any} source - The Display Object to test from.
     * @param {any} target - The Display Object to test to.
     * @param {boolean} [world=false] - Calculate the angle using World coordinates (true), or Object coordinates (false, the default)
     * @return {number} The angle in radians between the source and target display objects.
     */
    angleBetween: function (source, target, world)
    {

        if (world === undefined) { world = false; }

        if (world)
        {
            return Phaser.Point.angle(target.world, source.world);
        }
        else
        {
            return Phaser.Point.angle(target, source);
        }

    },

    /**
     * Find the angle in radians between centers of two display objects (like Sprites).
     *
     * @method Phaser.Physics.Arcade#angleBetweenCenters
     * @param {any} source - The Display Object to test from.
     * @param {any} target - The Display Object to test to.
     * @return {number} The angle in radians between the source and target display objects.
     */
    angleBetweenCenters: function (source, target)
    {

        var dx = target.centerX - source.centerX;
        var dy = target.centerY - source.centerY;

        return Math.atan2(dy, dx);

    },

    /**
     * Find the angle in radians between a display object (like a Sprite) and the given x/y coordinate.
     *
     * The optional `world` argument allows you to return the result based on the Game Objects `world` property,
     * instead of its `x` and `y` values. This is useful of the object has been nested inside an offset Group,
     * or parent Game Object.
     *
     * @method Phaser.Physics.Arcade#angleToXY
     * @param {any} displayObject - The Display Object to test from.
     * @param {number} x - The x coordinate to get the angle to.
     * @param {number} y - The y coordinate to get the angle to.
     * @param {boolean} [world=false] - Calculate the angle using World coordinates (true), or Object coordinates (false, the default)
     * @return {number} The angle in radians between displayObject.x/y to Pointer.x/y
     */
    angleToXY: function (displayObject, x, y, world)
    {

        if (world === undefined) { world = false; }

        if (world)
        {
            return Math.atan2(y - displayObject.world.y, x - displayObject.world.x);
        }
        else
        {
            return Math.atan2(y - displayObject.y, x - displayObject.x);
        }

    },

    /**
     * Find the angle in radians between a display object (like a Sprite) and a Pointer, taking their x/y and center into account.
     *
     * The optional `world` argument allows you to return the result based on the Game Objects `world` property,
     * instead of its `x` and `y` values. This is useful of the object has been nested inside an offset Group,
     * or parent Game Object.
     *
     * @method Phaser.Physics.Arcade#angleToPointer
     * @param {any} displayObject - The Display Object to test from.
     * @param {Phaser.Pointer} [pointer] - The Phaser.Pointer to test to. If none is given then Input.activePointer is used.
     * @param {boolean} [world=false] - Calculate the angle using World coordinates (true), or Object coordinates (false, the default)
     * @return {number} The angle in radians between displayObject.x/y to Pointer.x/y
     */
    angleToPointer: function (displayObject, pointer, world)
    {

        if (pointer === undefined) { pointer = this.game.input.activePointer; }
        if (world === undefined) { world = false; }

        if (world)
        {
            return Math.atan2(pointer.worldY - displayObject.world.y, pointer.worldX - displayObject.world.x);
        }
        else
        {
            return Math.atan2(pointer.worldY - displayObject.y, pointer.worldX - displayObject.x);
        }

    },

    /**
     * Find the angle in radians between a display object (like a Sprite) and a Pointer,
     * taking their x/y and center into account relative to the world.
     *
     * @method Phaser.Physics.Arcade#worldAngleToPointer
     * @param {any} displayObject - The DisplayObjerct to test from.
     * @param {Phaser.Pointer} [pointer] - The Phaser.Pointer to test to. If none is given then Input.activePointer is used.
     * @return {number} The angle in radians between displayObject.world.x/y to Pointer.worldX / worldY
     */
    worldAngleToPointer: function (displayObject, pointer)
    {

        return this.angleToPointer(displayObject, pointer, true);

    }

};
