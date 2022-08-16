package main

import "core:fmt"
import "core:runtime"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

SHIP_IDX :: 0
LASER_IDX :: 1

WINDOW_TITLE :: "Asteroids"
// WINDOW_X : i32 = 400
// WINDOW_Y : i32 = 400
WINDOW_X : i32 = SDL.WINDOWPOS_UNDEFINED // centered
WINDOW_Y : i32 = SDL.WINDOWPOS_UNDEFINED
WINDOW_W : i32 = 800
WINDOW_H : i32 = 600
WINDOW_FLAGS  :: SDL.WINDOW_SHOWN // force show on screen

Entity :: struct
{
	tex: ^SDL.Texture,
	source: ^SDL.Rect,
	dest: ^SDL.Rect,
}

CTX :: struct
{
	game_over: bool,
	window: ^SDL.Window,
	renderer: ^SDL.Renderer,

	entities: [3]Entity,
	moving_up: bool,
	moving_down: bool,
	moving_left: bool,
	moving_right: bool,

	velocity: f64,
	now_time: f64,
	prev_time: f64,
	delta_time: f64,
}

ctx := CTX{game_over = false}

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

		ship_img : ^SDL.Surface = SDL_Image.Load("assets/ship_2.png")
		ship_tex := SDL.CreateTextureFromSurface(ctx.renderer, ship_img)

		if ship_tex == nil
		{
			fmt.println("Error")
		}

	    ship_entity := Entity{
	    	tex = ship_tex,
	    	source = &SDL.Rect{
	    		x = 0,
	    		y = 0,
	    		w = 32,
	    		h = 32,
			},
			dest = &SDL.Rect{
				x = 390,
				y = 530,
				w = 32,
				h = 32,
			}
	    }

	    ctx.entities[SHIP_IDX] = ship_entity


	    laser_img : ^SDL.Surface = SDL_Image.Load("assets/laser.png")
    }

    loop()

    // Cleanup
	SDL.DestroyWindow(ctx.window)
	SDL.Quit()

}


fire :: proc()
{
	// steps : i32 = 1
//
	// starting_position := [2]i32{ship.x, ship.y}
//
	// fmt.println("Starting position", starting_position)
//
	// laser.x = starting_position[0]
	// laser.y = starting_position[1]
//
	// fmt.println("fire thing...")
	// for
	// {
		// SDL.RenderClear(renderer)
		// SDL.RenderCopy(renderer, texture_laser, &laser_bg, &laser)
		// SDL.RenderCopy(renderer, texture_ship, &ship_source, &ship)
		// SDL.RenderPresent(renderer)
//
		// laser.y = laser.y - steps
//
		// SDL.Delay(1)
//
		// if laser.y < 0
		// {
			// break;
		// }
	// }
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
    	}


    	// draw
    	{

	    	SDL.RenderClear(ctx.renderer)
	    	for e, _ in ctx.entities
	    	{
		    	SDL.RenderCopy(ctx.renderer, e.tex, e.source, e.dest)
	    	}

	    	SDL.RenderPresent(ctx.renderer)

    	}

    }


}
