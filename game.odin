package game

import "core:fmt"
import rl "vendor:raylib"

/* Our game's state lives within this struct. In
order for hot reload to work the game's memory
must be transferable from one game DLL to
another when a hot reload occurs. We can do that
when all the game's memory live in here. */
GameMemory :: struct {
  some_state: int,
}

g_mem: ^GameMemory

/* Allocates the GameMemory that we use to store
our game's state. We assign it to a global2
variable so we can use it from the other
procedures. */
@(export)
game_init :: proc() {
  g_mem = new(GameMemory)
  rl.InitWindow(1280, 720, "My Odin + Raylib game")
}

/* Simulation and rendering goes here. Return
false when you wish to terminate the program. */
@(export)
game_update :: proc() -> bool {
  g_mem.some_state += 1
  fmt.println(g_mem.some_state)
  draw_game()
  return !rl.WindowShouldClose()
}

draw_game :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground({160, 200, 255, 255})
    rl.EndDrawing()
}

/* Called by the main program when the main loop
has exited. Clean up your memory here. */
@(export)
game_shutdown :: proc() {
  rl.CloseWindow()
  free(g_mem)
}

/* Returns a pointer to the game memory. When
to the game memory. It can then load a new game
hot reloading, the main program needs a pointer
hot reloading, the main program needs a pointer
DLL and tell it to use the same memory by calling
game_hot_reloaded on the new game DLL, supplying
it the game memory pointer. */
@(export)
game_memory :: proc() -> rawptr {
  return g_mem
}

/* Used to set the game memory pointer after a
hot reload occurs. See game_memory comments. */
@(export)
game_hot_reloaded :: proc(mem: ^GameMemory) {
  g_mem = mem
}
