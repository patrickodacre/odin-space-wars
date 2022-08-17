package main

import "core:fmt"
import "core:runtime"
import "core:math/rand"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

SHIP_IDX :: 0
ENEMY_IDX :: 1

LASER_SPEED :: 2

WINDOW_TITLE :: "Asteroids"
// WINDOW_X : i32 = 400
// WINDOW_Y : i32 = 400
WINDOW_X : i32 = SDL.WINDOWPOS_UNDEFINED // centered
WINDOW_Y : i32 = SDL.WINDOWPOS_UNDEFINED
WINDOW_W : i32 = 1200
WINDOW_H : i32 = 1000
WINDOW_FLAGS  :: SDL.WINDOW_SHOWN // force show on screen
SHIP_START_Y : i32 = 600
SHIP_START_X : i32 = 600

Entity :: struct
{
	tex: ^SDL.Texture,
	source: SDL.Rect,
	dest: SDL.Rect,
}

CTX :: struct
{
	game_over: bool,
	window: ^SDL.Window,
	renderer: ^SDL.Renderer,


	entities: [3]Entity,

	ship_img: ^SDL.Surface,
	ship_tex: ^SDL.Texture,

	enemy_img: ^SDL.Surface,
	enemy_tex: ^SDL.Texture,

	laser_img: ^SDL.Surface,
	laser_tex: ^SDL.Texture,
	lasers: [dynamic]Entity,

	moving_up: bool,
	moving_down: bool,
	moving_left: bool,
	moving_right: bool,
	shoot: bool,

	velocity: f64,
	now_time: f64,
	prev_time: f64,
	delta_time: f64,

	fire_count: u64,
}

ctx := CTX{
	game_over = false,
	lasers = make([dynamic]Entity, 0, 30),
}

main :: proc()
{

	// INIT SDL

    SDL.SetHint(SDL.HINT_RENDER_SCALE_QUALITY, "2")
    SDL.Init(SDL.INIT_EVERYTHING)
	SDL_Image.Init(SDL_Image.INIT_PNG)


	// INIT Resources
	{

	    ctx.window = SDL.CreateWindow(WINDOW_TITLE, WINDOW_X, WINDOW_Y, WINDOW_W, WINDOW_H, WINDOW_FLAGS)

	    ctx.renderer = SDL.CreateRenderer(
	    	ctx.window,
	    	-1,
	    	SDL.RENDERER_PRESENTVSYNC | SDL.RENDERER_ACCELERATED | SDL.RENDERER_TARGETTEXTURE
		)

	}

	// ENTITIES
    {

	    // SHIP

		ctx.ship_img = SDL_Image.Load("assets/ship_2.png")
		ctx.ship_tex = SDL.CreateTextureFromSurface(ctx.renderer, ctx.ship_img)

		if ctx.ship_tex == nil
		{
			fmt.println("Error")
		}

	    ship_entity := Entity{
	    	tex = ctx.ship_tex,
	    	source = SDL.Rect{
	    		x = 0,
	    		y = 0,
	    		w = 32,
	    		h = 32,
			},
			dest = SDL.Rect{
				x = 390,
				y = 530,
				w = 32,
				h = 32,
			}
	    }

	    ctx.entities[SHIP_IDX] = ship_entity

	    // ENEMY
		ctx.enemy_img = SDL_Image.Load("assets/ship_1.png")
		ctx.enemy_tex = SDL.CreateTextureFromSurface(ctx.renderer, ctx.enemy_img)

		if ctx.enemy_tex == nil
		{
			fmt.println("Error")
		}

	    enemy_entity := Entity{
	    	tex = ctx.enemy_tex,
	    	source = SDL.Rect{
	    		x = 0,
	    		y = 0,
	    		w = 32,
	    		h = 32,
			},
			dest = SDL.Rect{
				x = 390,
				y = 10,
				w = 32,
				h = 32,
			}
	    }

	    ctx.entities[ENEMY_IDX] = enemy_entity



	    // LASERS

	    ctx.laser_img = SDL_Image.Load("assets/laser.png")
	    ctx.laser_tex = SDL.CreateTextureFromSurface(ctx.renderer, ctx.laser_img)

	    for i in 0..=5
	    {

	    	laser := Entity{
	    		tex = ctx.laser_tex,
	    		source = SDL.Rect{
	    			x = 0,
	    			y = 0,
	    			w = 32,
	    			h = 32,
    			},
	    		dest = SDL.Rect{
	    			x = 0,
	    			y = i32(i),
	    			w = 32,
	    			h = 32
	    		}
	    	}

	    	append(&ctx.lasers, laser)
	    }

    }

    loop()

    // Cleanup
	SDL.DestroyWindow(ctx.window)
	SDL.Quit()

}

loop :: proc()
{
	ctx.velocity = 400
	ctx.now_time = f64(SDL.GetPerformanceCounter())
	ctx.prev_time = 0
	ctx.delta_time =  0.001

	event : SDL.Event

	for !ctx.game_over
    {
    	// process input
    	{

		    ctx.now_time = f64(SDL.GetPerformanceCounter()) / f64(SDL.GetPerformanceFrequency())
		    ctx.delta_time = ctx.now_time - ctx.prev_time
		    ctx.prev_time = ctx.now_time

	    	if SDL.PollEvent(&event)
	    	{
	    		if event.type == SDL.EventType.QUIT
	    		{
	    			ctx.game_over = true
	    		}

				if event.type == SDL.EventType.KEYDOWN
				{
					state := SDL.GetKeyboardState(nil)

					ctx.moving_left = state[SDL.Scancode.A] > 0
					ctx.moving_right = state[SDL.Scancode.D] > 0
					ctx.moving_up = state[SDL.Scancode.W] > 0
					ctx.moving_down = state[SDL.Scancode.S] > 0

					#partial switch event.key.keysym.scancode
					{
						case .RETURN:
							fmt.println(len(ctx.lasers))
							for l, _ in ctx.lasers
							{
								fmt.println(l)
							}
						case .SPACE:
							fmt.println("FIRE!")
							ctx.shoot = true
					}


				}

				if event.type == SDL.EventType.KEYUP
				{

					state := SDL.GetKeyboardState(nil)

					ctx.moving_left = state[SDL.Scancode.A] > 0
					ctx.moving_right = state[SDL.Scancode.D] > 0
					ctx.moving_up = state[SDL.Scancode.W] > 0
					ctx.moving_down = state[SDL.Scancode.S] > 0

				}
	    	}

    	}

    	// update
    	{

    		// UPDATE SHIP
	    	if ctx.moving_left
	    	{
				ctx.entities[SHIP_IDX].dest.x -= i32(ctx.velocity * ctx.delta_time)
	    	}

			if ctx.moving_right
			{
				ctx.entities[SHIP_IDX].dest.x += i32(ctx.velocity * ctx.delta_time)
			}

			if ctx.moving_up
			{
				ctx.entities[SHIP_IDX].dest.y -= i32(ctx.velocity * ctx.delta_time)
			}

			if ctx.moving_down
			{
				ctx.entities[SHIP_IDX].dest.y += i32(ctx.velocity * ctx.delta_time)
			}

			// UPDATE LASER
			if ctx.shoot
			{

				fmt.println("SHOOTING!")
				starting_x := ctx.entities[SHIP_IDX].dest.x
				starting_y := ctx.entities[SHIP_IDX].dest.y

				found := false

				// reuse existing lasers
				check: for l, _ in &ctx.lasers
				{
					if l.dest.y < 0
					{
						l.dest.x = starting_x
						l.dest.y = starting_y
						fmt.println("FOUND!")
						fmt.println("FOUND!")
						found = true
						break check
					}
				}

				if !found
				{

					append(&ctx.lasers, Entity{
						tex = ctx.laser_tex,
						source = SDL.Rect{
							x = 0,
							y = 0,
							w = 32,
							h = 32,
						},
						dest = SDL.Rect{
							x = starting_x,
							y = starting_y,
							w = 32,
							h = 32,
						}
					})

				}

			}

			ctx.shoot = false

			enemy := &ctx.entities[ENEMY_IDX]

			// SHOOT LASERS
			for l, idx in &ctx.lasers
			{
				if (l.dest.y > 0)
				{
					l.dest.y -= i32((ctx.velocity * LASER_SPEED) * ctx.delta_time)

					bounds_x_left := l.dest.x - 20
					bounds_x_right := l.dest.x + 20

					bounds_y_bottom := l.dest.y + 5

					// HIT ENEMY?
					if enemy.dest.x >= bounds_x_left &&
						enemy.dest.x <= bounds_x_right &&
						enemy.dest.y >= bounds_y_bottom
					{
						fmt.println("HIT!")
						// TODO: respawn the enemy
						num := rand.int_max(150 - 20) + 20
						num_2 := rand.int_max(150 - 20) + 20

						// if num > num_2
						// {
							new_x_left := enemy.dest.x - i32(num)
							new_x_right := enemy.dest.x + i32(num)


							if new_x_left > 0
							{
								enemy.dest.x = new_x_left
							}
							else if new_x_right < (WINDOW_W - 20)
							{
								enemy.dest.x = new_x_right
							}

							new_y_up := enemy.dest.y - i32(num)
							new_y_down := enemy.dest.y + i32(num)

							if new_y_up > 20
							{
								enemy.dest.y = new_y_up
							}
							else if new_y_down < (WINDOW_H - 20)
							{
								enemy.dest.y = new_y_down
							}

						// }
						// else
						// {
							// new_x := enemy.dest.x + i32(num_2)
							// new_y := enemy.dest.y + i32(num)
//
							// if new_x > 10
							// {
								// enemy.dest.x += i32(num_2)
							// }
							// if new_y > 10
							// {
								// enemy.dest.y -= i32(num)
							// }
//
//
						// }
					}
				}
			}

    	}


    	// draw
    	{

	    	SDL.RenderClear(ctx.renderer)
	    	for e, _ in &ctx.entities
	    	{
		    	SDL.RenderCopy(ctx.renderer, e.tex, &e.source, &e.dest)
	    	}

	    	for l, _ in &ctx.lasers
	    	{
	    		if l.dest.y > 0
	    		{
		    		SDL.RenderCopy(ctx.renderer, l.tex, &l.source, &l.dest)
	    		}
	    	}

	    	SDL.RenderPresent(ctx.renderer)

    	}

    }


}
