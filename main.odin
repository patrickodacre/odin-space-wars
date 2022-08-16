package main

import "core:fmt"
import "core:runtime"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"



//

// Entity :: struct
// {
	// tex: ^SDL.Texture,
	// source: ^SDL.Rect,
	// dest: ^SDL.Rect,
// }

CTX :: struct
{
	window : ^SDL.Window,

	entities: [3]Entity,
}

ctx := CTX{}

window : ^SDL.Window
renderer : ^SDL.Renderer
renderer_2 : ^SDL.Renderer
texture_ship : ^SDL.Texture
texture_laser : ^SDL.Texture
ship_source : SDL.Rect
ship : SDL.Rect
laser_bg : SDL.Rect
laser : SDL.Rect

move_up := false
move_down := false
move_left := false
move_right := false

ship_index := 0
laser_index := 1

Entity :: struct
{
	t: ^SDL.Texture,
	b: SDL.Rect,
	r: SDL.Rect,
}

entities := [3]Entity{}

main :: proc()
{

	// INIT SDL

	event : SDL.Event
    SDL.SetHint(SDL.HINT_RENDER_SCALE_QUALITY, "2")
    SDL.Init(SDL.INIT_EVERYTHING)


	// INIT Resources



    //Create a window with a title, "Getting Started", in the centre
    //(or undefined x and y positions), with dimensions of 800 px width
    //and 600 px height and force it to be shown on screen
    window = SDL.CreateWindow("Asteroids", SDL.WINDOWPOS_UNDEFINED, SDL.WINDOWPOS_UNDEFINED, 800, 600, SDL.WINDOW_SHOWN)
    renderer = SDL.CreateRenderer(
    	window,
    	-1,
    	SDL.RENDERER_PRESENTVSYNC | SDL.RENDERER_ACCELERATED | SDL.RENDERER_TARGETTEXTURE
    	)
    // renderer_2 = SDL.CreateRenderer(window, -1, SDL.RENDERER_ACCELERATED)


    // ship_source
    // this holds the ship image
    ship_source.x = 0
    ship_source.y = 0
    ship_source.w = 32
    ship_source.h = 32

    // but this is the window that can be moved around on the screen.
    // why 2? b/c RenderCopy needs both a source (ship_source) and destination (ship)
    // position of the ship
    ship.x = 390
    ship.y = 530
    ship.w = 32
    ship.h = 32


    laser_bg.x = 0
    laser_bg.y = 0
    laser_bg.w = 32
    laser_bg.h = 32

    laser.x = 40
    laser.y = 40
    laser.w = 32
    laser.h = 32


    // create our texture
	{
		screen : ^SDL.Surface
		image : ^SDL.Surface

		// screen
		screen = SDL.GetWindowSurface(window)

		SDL_Image.Init(SDL_Image.INIT_PNG)




		image = SDL_Image.Load("assets/ship_2.png")

		texture_ship = SDL.CreateTextureFromSurface(renderer, image)
		// created texture, so we're done with the surface
		SDL.FreeSurface(image)

		image = SDL_Image.Load("assets/laser.png")
		texture_laser = SDL.CreateTextureFromSurface(renderer, image)
		SDL.FreeSurface(image)

	}

	// load our positions
    entities[ship_index] = Entity{t = texture_ship, b = ship_source, r = ship}
    entities[laser_index] = Entity{t = texture_laser, b = laser_bg, r = laser}

	// time

	velocity : f64 = 400
	now := f64(SDL.GetPerformanceCounter())
	prev_time : f64 = 0
	delta_time : f64 =  0.01
	FPS : f64 : 60

	// game loop
    for
    {
	    now = f64(SDL.GetPerformanceCounter()) / f64(SDL.GetPerformanceFrequency())
	    delta_time = now - prev_time
	    prev_time = now

    	if SDL.PollEvent(&event)
    	{
    		if event.type == SDL.EventType.QUIT
    		{
    			break;
    		}

			if event.type == SDL.EventType.KEYDOWN
			{
				state := SDL.GetKeyboardState(nil)

				move_left = state[SDL.Scancode.A] > 0
				move_right = state[SDL.Scancode.D] > 0
				move_up = state[SDL.Scancode.W] > 0
				move_down = state[SDL.Scancode.S] > 0
			}

			if event.type == SDL.EventType.KEYUP
			{

				state := SDL.GetKeyboardState(nil)

				move_left = state[SDL.Scancode.A] > 0
				move_right = state[SDL.Scancode.D] > 0
				move_up = state[SDL.Scancode.W] > 0
				move_down = state[SDL.Scancode.S] > 0
			}
    	}

    	if move_left
    	{
			entities[ship_index].r.x -= i32(velocity * delta_time)
    	}

		if move_right
		{
			entities[ship_index].r.x += i32(velocity * delta_time)
		}

		if move_up
		{
			entities[ship_index].r.y -= i32(velocity * delta_time)
		}

		if move_down
		{
			entities[ship_index].r.y += i32(velocity * delta_time)
		}

    	SDL.RenderClear(renderer)
    	for e, _ in entities
    	{

	    	t := e.t
	    	b := e.b
	    	r := e.r
	    	SDL.RenderCopy(renderer, t, &b, &r)
    	}


    	SDL.RenderPresent(renderer)

    }


    // Cleanup
	SDL.DestroyWindow(window)
	SDL.Quit()

}


fire :: proc()
{
	steps : i32 = 1

	starting_position := [2]i32{ship.x, ship.y}

	fmt.println("Starting position", starting_position)

	laser.x = starting_position[0]
	laser.y = starting_position[1]

	fmt.println("fire thing...")
	for
	{
		SDL.RenderClear(renderer)
		SDL.RenderCopy(renderer, texture_laser, &laser_bg, &laser)
		SDL.RenderCopy(renderer, texture_ship, &ship_source, &ship)
		SDL.RenderPresent(renderer)

		laser.y = laser.y - steps

		SDL.Delay(1)

		if laser.y < 0
		{
			break;
		}
	}
}
