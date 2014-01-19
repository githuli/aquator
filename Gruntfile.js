module.exports = function(grunt){
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-connect');
    grunt.loadNpmTasks('grunt-coffee-jshint');

    grunt.initConfig({
        connect: {
            server: {
              options: {
                    port: 1337,
                    base: './'
                }
            }
        },
        coffee_jshint: {
            options: {
                "indent": 4,
            },
            files: {
                'src': 'src/*.coffee'
            }
        },
        coffee:{
            compileJoined: {
                options: {
                    join: true
                },
                files: {
                    'js/game.js': [
                        'src/engine.coffee',
                        'src/aquator.coffee',
                    ],
                }
            },
        },
        watch: {
            coffee: {
                files: ['src/*.coffee'],
                tasks: ['coffee']
            }
        }
    });
    grunt.registerTask('default',[
        'coffee', 'connect', 'watch'
    ]);
};
