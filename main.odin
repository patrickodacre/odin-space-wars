package main

import "core:fmt"
import "core:runtime"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

main :: proc()
{

	/* SDL.CreateShapedWindow("Thing Window", 0, 1, 800, 600, SDL.WINDOW_FULLSCREEN) */
	event : SDL.Event

    //Initialize all the systems of SDL
    SDL.Init(SDL.INIT_EVERYTHING)

    //Create a window with a title, "Getting Started", in the centre
    //(or undefined x and y positions), with dimensions of 800 px width
    //and 600 px height and force it to be shown on screen
		/* SDL.Window*  */
    window := SDL.CreateWindow("Asteroids", SDL.WINDOWPOS_UNDEFINED, SDL.WINDOWPOS_UNDEFINED, 800, 600, SDL.WINDOW_SHOWN)

    //Create a renderer for the window created above, with the first display driver present
    //and with no additional settings
    /* SDL.Renderer* */
    renderer := SDL.CreateRenderer(window, -1, SDL.RENDERER_SOFTWARE)

	screen : ^SDL.Surface
	image : ^SDL.Surface

	screen = SDL.GetWindowSurface(window)

	SDL_Image.Init(SDL_Image.INIT_PNG)
	image = SDL_Image.Load("assets/ship_2.png")

	// image = SDL.LoadBMP("assets/bardo.bmp")

	SDL.BlitSurface(image, nil, screen, nil)
	SDL.FreeSurface(image)
	SDL.UpdateWindowSurface(window)

    for
    {

    	if SDL.PollEvent(&event) == 1
    	{
    		if event.type == SDL.EventType.QUIT
    		{
    			break;
    		}

    		if event.button.button == SDL.BUTTON_RIGHT
    		{
    			// fmt.println("right button clicked")
    			// SDL.LockSurface(screen)
    			// runtime.memset(screen.pixels, 255, int(screen.h * screen.pitch))
    			// SDL.UnlockSurface(screen)

    			// SDL.UpdateWindowSurface(window)
    		}
    	}

    }

	SDL.DestroyWindow(window)
	SDL.Quit()

}
