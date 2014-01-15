
class Game
	constructor : () ->
		@repository = new GameObjectRepository()
		@eventhandler = new GameEventHandler()
		@eventhandler = new AssetLibrary(
	        sprites:
	            ship : "gfx/ship.png",
	            missile : "gfx/missile.png",
	            enemy : "gfx/enemy.png",
	            explosion : "gfx/plop.png"
	        spriteclips:
	            clip1 : [ "gfx/test{0}", 1, 30 ]	        	
			)
