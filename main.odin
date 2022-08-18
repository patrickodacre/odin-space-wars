package main

import "core:fmt"
import "core:runtime"
import "core:math/rand"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

SHIP_IDX :: 0
SHIP_SPEED :: 2

MOBS_ROW :: 5
MAX_LASERS :: 20
LASER_SPEED :: 3
MOB_SPEED :: 1
MOB_SPEED_DIVISOR :: 2

WINDOW_TITLE :: "Asteroids"
WINDOW_X : i32 = SDL.WINDOWPOS_UNDEFINED // centered
WINDOW_Y : i32 = SDL.WINDOWPOS_UNDEFINED
WINDOW_W : i32 = 1200
WINDOW_H : i32 = 1000
WINDOW_FLAGS  :: SDL.WINDOW_SHOWN // force show on screen
SHIP_START_Y : i32 = (WINDOW_H / 10) * 9
SHIP_START_X : i32 = (WINDOW_W / 2) - 32

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

	mob_speed: f64,
	mob_img: ^SDL.Surface,
	mob_tex: ^SDL.Texture,
	mobs: [dynamic]Entity,
	mobs_moving_right: bool,

	laser_speed : f64,
	laser_img: ^SDL.Surface,
	laser_tex: ^SDL.Texture,
	lasers: [dynamic]Entity,

	moving_up: bool,
	moving_down: bool,
	moving_left: bool,
	moving_right: bool,
	shooting: bool,

	velocity: f64,
	now_time: f64,
	prev_time: f64,
	delta_time: f64,

	fire_count: u64,
}

ctx := CTX{
	game_over = false,
	mob_speed = MOB_SPEED,
	laser_speed = LASER_SPEED,
	lasers = make([dynamic]Entity, 0, MAX_LASERS),
	mobs = make([dynamic]Entity, 0, 30),
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
				x = SHIP_START_X,
				y = SHIP_START_Y,
				w = 32,
				h = 32,
			}
	    }

	    ctx.entities[SHIP_IDX] = ship_entity

	    // ENEMY
		ctx.mob_img = SDL_Image.Load("assets/ship_1.png")
		ctx.mob_tex = SDL.CreateTextureFromSurface(ctx.renderer, ctx.mob_img)

		if ctx.mob_tex == nil
		{
			fmt.println("Error")
		}

		for i in 1..=MOBS_ROW
		{

		    mob_entity := Entity{
		    	tex = ctx.mob_tex,
		    	source = SDL.Rect{
		    		x = 0,
		    		y = 0,
		    		w = 32,
		    		h = 32,
				},
				dest = SDL.Rect{
					x = (WINDOW_W - 64) / MOBS_ROW * i32(i),
					y = 30,
					w = 32,
					h = 32,
				}
		    }

		    append(&ctx.mobs, mob_entity)
		}


	    // LASERS

	    ctx.laser_img = SDL_Image.Load("assets/laser.png")
	    ctx.laser_tex = SDL.CreateTextureFromSurface(ctx.renderer, ctx.laser_img)

	    // create ALL lasers
	    for i in 1..=MAX_LASERS
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
	    			y = -1,
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
    ctx.prev_time = f64(SDL.GetPerformanceCounter()) / f64(SDL.GetPerformanceFrequency())
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
							fmt.println("Lasers ::", len(ctx.lasers))
							for l, _ in ctx.lasers
							{
								fmt.println(l)
							}

							fmt.println("Mobs ::", len(ctx.mobs))
							for m, _ in ctx.mobs
							{
								fmt.println(m)
							}
						case .SPACE:
							fmt.println("FIRE!")
							ctx.shooting = true
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
    		ship := &ctx.entities[SHIP_IDX]

	    	if ctx.moving_left
	    	{
	    		new_x := ship.dest.x - i32((ctx.velocity * SHIP_SPEED) * ctx.delta_time)

	    		if new_x > 0
	    		{
					ship.dest.x = new_x
	    		}
	    	}

			if ctx.moving_right
			{
	    		new_x := ship.dest.x + i32((ctx.velocity * SHIP_SPEED) * ctx.delta_time)

	    		if new_x < (WINDOW_W - 32)
	    		{
					ship.dest.x = new_x
	    		}
			}

			if ctx.moving_up
			{
				new_y := ship.dest.y - i32((ctx.velocity * SHIP_SPEED) * ctx.delta_time)

				if new_y > 0
				{
					ship.dest.y = new_y
				}
			}

			if ctx.moving_down
			{
				new_y := ship.dest.y + i32((ctx.velocity * SHIP_SPEED) * ctx.delta_time)

				if new_y < (WINDOW_H - 32)
				{
					ship.dest.y = new_y
				}
			}

			// UPDATE LASER
			if ctx.shooting
			{

				starting_x := ctx.entities[SHIP_IDX].dest.x
				starting_y := ctx.entities[SHIP_IDX].dest.y

				has_ammo := false

				// reuse existing lasers
				reload: for l, _ in &ctx.lasers
				{
					if l.dest.y < 0
					{
						has_ammo = true

						l.dest.x = starting_x
						l.dest.y = starting_y

						break reload
					}
				}

				if !has_ammo
				{
					fmt.println("out of ammo!")
				}

			}

			ctx.shooting = false

			// SHOOT LASERS
			shooting: for l, idx in &ctx.lasers
			{
				// if y > 0 then we've fired a laser
				if (l.dest.y > 0)
				{
					l.dest.y -= i32((ctx.velocity * ctx.laser_speed) * ctx.delta_time)

					bounds_x_left := l.dest.x - 20
					bounds_x_right := l.dest.x + 20

					// don't care if the laser is BEHIND the mob
					bounds_y_bottom := l.dest.y + 5

					// check ALL mobs
					for m, idx in &ctx.mobs
					{

						// HIT MOB?
						if m.dest.x >= bounds_x_left &&
							m.dest.x <= bounds_x_right &&
							m.dest.y >= bounds_y_bottom
						{

							// TODO: increase points
							fmt.println("HIT!")

							// unordered_remove makes the mobs change direction at unexpected times
							ordered_remove(&ctx.mobs, idx)
							// reset the laser to make it available again
							l.dest.y = -1

							// TODO: check all killed? WIN!
						}
					}

				}
			}

			// moving mobs
			if (len(ctx.mobs) > 0)
			{

				rightmost_mob := ctx.mobs[len(ctx.mobs) - 1]
				leftmost_mob := ctx.mobs[0]

				rightmost_x := rightmost_mob.dest.x
				leftmost_x := leftmost_mob.dest.x

				if rightmost_x >= (WINDOW_W - 32)
				{
					ctx.mobs_moving_right = false
				}
				else if leftmost_x <= 0
				{
					ctx.mobs_moving_right = true
				}

				moving_mobs: for m, _ in &ctx.mobs
				{

					if ctx.mobs_moving_right
					{
						move_by := i32((ctx.velocity * ctx.mob_speed) * ctx.delta_time)
						m.dest.x += move_by / MOB_SPEED_DIVISOR
					}
					else
					{
						move_by := i32((ctx.velocity * ctx.mob_speed) * ctx.delta_time)
						m.dest.x -= move_by / MOB_SPEED_DIVISOR
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

	    	for m, _ in &ctx.mobs
	    	{
	    		SDL.RenderCopy(ctx.renderer, m.tex, &m.source, &m.dest)
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
