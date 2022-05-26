package main

import "core:fmt"
import "core:runtime"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

window : ^SDL.Window
renderer : ^SDL.Renderer
renderer_2 : ^SDL.Renderer
texture : ^SDL.Texture
texture_laser : ^SDL.Texture
ship_bg : SDL.Rect
ship : SDL.Rect
laser_bg : SDL.Rect
laser : SDL.Rect

main :: proc()
{

	event : SDL.Event
    SDL.Init(SDL.INIT_EVERYTHING)


    //Create a window with a title, "Getting Started", in the centre
    //(or undefined x and y positions), with dimensions of 800 px width
    //and 600 px height and force it to be shown on screen
    window = SDL.CreateWindow("Asteroids", SDL.WINDOWPOS_UNDEFINED, SDL.WINDOWPOS_UNDEFINED, 800, 600, SDL.WINDOW_SHOWN)
    renderer = SDL.CreateRenderer(window, -1, SDL.RENDERER_ACCELERATED)
    // renderer_2 = SDL.CreateRenderer(window, -1, SDL.RENDERER_ACCELERATED)


    // ship_bg
    // this holds the ship image
    ship_bg.x = 0
    ship_bg.y = 0
    ship_bg.w = 32
    ship_bg.h = 32

    // but this is the window that can be moved around on the screen.
    // why 2? b/c RenderCopy needs both a source (ship_bg) and destination (ship)
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

		screen = SDL.GetWindowSurface(window)

		SDL_Image.Init(SDL_Image.INIT_PNG)
		image = SDL_Image.Load("assets/ship_2.png")

		texture = SDL.CreateTextureFromSurface(renderer, image)
		// created texture, so we're done with the surface
		SDL.FreeSurface(image)

		image_2 := SDL_Image.Load("assets/laser.png")
		texture_laser = SDL.CreateTextureFromSurface(renderer, image_2)
		SDL.FreeSurface(image_2)

	}

	// game loop
    for
    {

    	if SDL.PollEvent(&event) == 1
    	{
    		if event.type == SDL.EventType.QUIT
    		{
    			break;
    		}

    		#partial switch event.type {

	    		case .KEYDOWN:
    				do_action(event.key.keysym.scancode)
    		}

    	}


    	SDL.RenderClear(renderer)
    	SDL.RenderCopy(renderer, texture, &ship_bg, &ship)
    	// SDL.RenderCopy(renderer, texture_laser, &laser_bg, &laser)
    	SDL.RenderPresent(renderer)

    }

	SDL.DestroyWindow(window)
	SDL.Quit()

}

update_position :: proc(x, y: i32)
{
	ship.x = x
	ship.y = y
	SDL.RenderCopy(renderer, texture, &ship_bg, &ship)
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
		SDL.RenderCopy(renderer, texture, &ship_bg, &ship)
		SDL.RenderPresent(renderer)

		laser.y = laser.y - steps

		SDL.Delay(1)

		if laser.y < 0
		{
			break;
		}
	}
}

do_action :: proc(key: SDL.Scancode)
{
	steps : i32 = 10

	#partial switch key {

		case .W:
			fmt.println("Forward")

			update_position(ship.x, ship.y - steps)
		case .S:
			fmt.println("Backward")
			update_position(ship.x, ship.y + steps)
		case .D:
			fmt.println("Right")
			update_position(ship.x + steps, ship.y)
		case .A:
			fmt.println("Left")
			update_position(ship.x - steps, ship.y)
		case .SPACE:
			fmt.println("Fire!!")
			fire()
	}

}
