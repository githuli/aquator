
class Game
	constructor : () ->
		@repository = new GameObjectRepository()
		@eventhandler = new GameEventHandler()
		@eventhandler = new AssetLibrary(
	        spriteassets:
	            ship : "ship.png",
	            missile : "missile.png",
	            enemy : "enemy.png",
	            explosion : "plop.png"
	        spriteclipassets:
	            clip1 : [ "gfx/test{0}.png", 30 ]	        	
			)
