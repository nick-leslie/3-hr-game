package game

import "core:fmt"
import rl "vendor:raylib"

//clicker code below
characters: rl.Texture
// slots code below
slots_mult :: [6]f64{0.2,0.3,0.4,0.8,1.0,2.0}
slots_chance:: [6]i64{50,60,70,80,90,95} // get above

/* Our game's state lives within this struct. In
order for hot reload to work the game's memory
must be transferable from one game DLL to
another when a hot reload occurs. We can do that
when all the game's memory live in here. */
GameMemory :: struct {
  some_state: int,
  //clicker code below
  num_sacrificed: int,
  sacrifice_pos_rect: rl.Rectangle,
  sacrifice_texture_rect: rl.Rectangle,
  num_sacrificed_text_pos: Position,
  current_character_x: int,
  current_character_y: int,
  // slots code below
}

g_mem: ^GameMemory

Position :: struct {
    x: i32,
    y: i32
}

/* Allocates the GameMemory that we use to store
our game's state. We assign it to a global2
variable so we can use it from the other
procedures. */
@(export)
game_init :: proc() {
  g_mem = new(GameMemory)
  rl.InitWindow(1280, 720, "Lets go gambling!")
  //clicker code below
  // Set initial values
  g_mem.num_sacrificed = 0
  g_mem.sacrifice_pos_rect = {1000, 360, 100, 100}
  g_mem.sacrifice_texture_rect = {0, 0, 32, 32}
  g_mem.num_sacrificed_text_pos = {800, 290}
  // Load in the character
  characters = rl.LoadTexture("assets/32rogues/rogues.png")


  // slots code below
}

/* Simulation and rendering goes here. Return
false when you wish to terminate the program. */
@(export)
game_update :: proc() -> bool {
  g_mem.some_state += 1
  //fmt.println(g_mem.some_state)
  //clicker code below
  character_clicked()
  
  // slots code below

  draw_game()
  return !rl.WindowShouldClose()
}

draw_game :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground({160, 200, 255, 255})
    //clicker code below
    rl.DrawTexturePro(characters, g_mem.sacrifice_texture_rect, g_mem.sacrifice_pos_rect, {0, 0}, 0, rl.WHITE)
    sacrificed_text := fmt.ctprintf("Number of sacrifices:\n%d", g_mem.num_sacrificed)
    rl.DrawText(sacrificed_text, g_mem.num_sacrificed_text_pos.x, g_mem.num_sacrificed_text_pos.y, 36, rl.BLACK)

    // slots code below
    rl.EndDrawing()
}

/* Called by the main program when the main loop
has exited. Clean up your memory here. */
@(export)
game_shutdown :: proc() {
    //clicker code below
    rl.UnloadTexture(characters)

    // slots code below

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



//clicker code below
character_clicked :: proc() {
    mouse_x := rl.GetMouseX()
    mouse_y := rl.GetMouseY()
    if(!rl.IsMouseButtonPressed(rl.MouseButton.LEFT)){
        return;
    }
    
    mouse_vec : rl.Vector2 = {auto_cast mouse_x, auto_cast mouse_y}
    if (rl.CheckCollisionPointRec(mouse_vec, g_mem.sacrifice_pos_rect)){
        g_mem.num_sacrificed += 1
        g_mem.current_character_x = auto_cast rl.GetRandomValue(0, 4) * 32
        g_mem.current_character_y = auto_cast rl.GetRandomValue(0, 6) * 32
        g_mem.sacrifice_texture_rect = {auto_cast g_mem.current_character_x, auto_cast g_mem.current_character_y, 32, 32}
    }
}

// slots code below
