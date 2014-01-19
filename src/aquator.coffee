
class Game
	constructor : () ->
		@repository = new GameObjectRepository()
		@eventhandler = new GameEventHandler()
		@assets = new AssetLibrary(
	        sprites:
	            ship : { file: "ship.png" },
	            missile : { file: "missile.png" },
	            enemy : { file: "enemy.png" },
	            explosion : { file: "plop.png" },
	            clip1 : { file: "gfx/test{0}.png", startframe:0, endframe:30 }
	        datadir:
	        	'res/sprites/'
		)

	start : () ->
		console.log("starting up AQUATOR..")
		@


window.AquatorGame = new Game()
window.AquatorGame.start()
