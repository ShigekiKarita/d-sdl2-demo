/++

PNGs are retrieved from
https://postd.cc/writing-a-2d-platform-game-in-nim-with-sdl2/

 +/

import std.stdio : writeln;
import std.exception : enforce;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import sdlite : Event, Window, Texture;

enum Input {
    none,
    left,
    right,
    jump,
    restart,
    quit
}

Input toInput(SDL_Scancode key) {
    with (Input) {
        switch (key) {
        case SDL_SCANCODE_A: return left;
        case SDL_SCANCODE_D: return right;
        case SDL_SCANCODE_SPACE: return jump;
        case SDL_SCANCODE_R: return restart;
        case SDL_SCANCODE_Q: return quit;
        default: return none;
        }
    }
}

struct Player {
    Texture texture;
    SDL_Point pos;
    double[2] vel;

    struct Parts {
        SDL_Rect src, dst;
        SDL_RendererFlip flip = SDL_FLIP_NONE;
    }

    enum bodyParts = [
        // "back feet shadow":
        Parts(SDL_Rect(192, 64, 64, 32), SDL_Rect(60,  0, 96, 48)),
        // "body shadow":
        Parts(SDL_Rect( 96,  0, 96, 96), SDL_Rect(48, 48, 96, 96)),
        // "front feet shadow":
        Parts(SDL_Rect(192, 64, 64, 32), SDL_Rect(36,  0, 96, 48)),
        // "back feet":
        Parts(SDL_Rect(192, 32, 64, 32), SDL_Rect(60,  0, 96, 48)),
        // "body":
        Parts(SDL_Rect(  0,  0, 96, 96), SDL_Rect(48, 48, 96, 96)),
        // "front feet":
        Parts(SDL_Rect(192, 32, 64, 32), SDL_Rect(36,  0, 96, 48)),
        // "left eye":
        Parts(SDL_Rect( 64, 96, 32, 32), SDL_Rect(18, 21, 36, 36)),
        // "right eye":
        Parts(SDL_Rect( 64, 96, 32, 32), SDL_Rect( 6, 21, 36, 36), SDL_FLIP_HORIZONTAL),
        ];

    auto render() {
        foreach (v; bodyParts) {
            with (v.dst) {
                auto dst = SDL_Rect(this.pos.x-x, this.pos.y-y, w, h);
                this.texture.copy(&v.src, &dst, 0.0, null, v.flip);
            }
        }
    }
}

struct GameState {
    bool[Input.max+1] inputs;
    double[2] camera;
}


void main() {
    enforce(SDL_Init(SDL_INIT_EVERYTHING) == 0,
            "SDL2 initialization failed");
    scope(exit) SDL_Quit();
    enforce(SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "2") == SDL_TRUE,
            "Linear texture filtering could not be enabled");

    auto window = Window("Our own 2D platformer", 1280, 720);
    auto renderer = window.renderer;
    renderer.setDrawColor(110, 132, 174);
    auto player = Player(renderer.loadTexture("asset/red_bird.png"), SDL_Point(170, 500));

    GameState game;
    while (true) {
        foreach (event; Event()) {
            // http://sdl2referencejp.osdn.jp/SDL_Event.html
            switch (event.type) {
            case SDL_QUIT:
                game.inputs[Input.quit] = true;
                break;
            case SDL_KEYDOWN:
                game.inputs[event.key.keysym.scancode.toInput] = true;
                break;
            case SDL_KEYUP:
                game.inputs[event.key.keysym.scancode.toInput] = false;
                break;
            default: assert(true);
            }
        }

        if (game.inputs[Input.quit]) {
            writeln("see you!");
            break;
        }
        if (game.inputs[Input.right]) {
            player.pos.x += 1;
        }
        if (game.inputs[Input.left]) {
            player.pos.x -= 1;
        }

        renderer.clear();
        player.render();
        renderer.present();
    }
}
