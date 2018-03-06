module sdlite;

import std.string : fromStringz;
import std.traits : isPointer;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

@nogc:

auto SDL_Enforce(SDL_bool cond) {
    assert(cond == SDL_TRUE, SDL_GetError().fromStringz);
}

auto SDL_Enforce(T)(T ptr) if (isPointer!T || is(T == bool)) {
    assert(ptr, SDL_GetError().fromStringz);
    static if (isPointer!T) {
        return ptr;
    }
}

shared static this() {
    SDL_Enforce(SDL_Init(SDL_INIT_EVERYTHING) == 0);
}

shared static ~this() {
    SDL_Quit();
}


struct Window {
    @nogc:

    SDL_Window* ptr;

    this(const(char)* title, int width, int height,
         int x=SDL_WINDOWPOS_CENTERED,
         int y=SDL_WINDOWPOS_CENTERED,
         SDL_WindowFlags flags=SDL_WINDOW_SHOWN
        ) {
        this.ptr = SDL_Enforce(SDL_CreateWindow(title, x, y, width, height, flags));
    }

    ~this() {
        SDL_DestroyWindow(this.ptr);
    }

    auto renderer() {
        return Renderer(this.ptr);
    }
}

struct Renderer {
    @nogc:

    SDL_Renderer* ptr;

    this(SDL_Window* window, int index=-1,
         SDL_RendererFlags flags=SDL_RENDERER_ACCELERATED // the renderer uses hardware acceleration
         | SDL_RENDERER_PRESENTVSYNC  // present is synchronized with the refresh rate
        ) {
        this.ptr = SDL_Enforce(SDL_CreateRenderer(window, index, flags));
    }

    ~this() {
        SDL_DestroyRenderer(this.ptr);
    }

    ref auto setDrawColor(ubyte r, ubyte g, ubyte b, ubyte a=SDL_ALPHA_OPAQUE) {
        SDL_Enforce(SDL_SetRenderDrawColor(this.ptr, r, g, b, a) == 0);
        return this;
    }

    ref clear() {
        assert(SDL_RenderClear(this.ptr) == 0);
        return this;
    }

    ref present() {
        SDL_RenderPresent(this.ptr);
        return this;
    }

    auto loadTexture(const(char)* filename) {
        return Texture(this.ptr, filename);
    }
}

struct EventQueue {
    @nogc:

    SDL_Event _event;
    bool _empty = false;
    bool _uninit = true;

    @property ref front() {
        if (_uninit) {
            _uninit = true;
            this.popFront();
        }
        return _event;
    }

    void popFront() {
        this._empty = SDL_PollEvent(&this._event) == 0;
    }

    @property bool empty() const {
        return this._empty;
    }
}

struct Texture {
    @nogc:

    SDL_Texture* ptr;
    SDL_Renderer* rptr;
    this(SDL_Renderer* r, const(char)* filename) {
        auto rwops = SDL_Enforce(SDL_RWFromFile(filename, "rb")); // , "cannot load a file: " ~ filename);
        scope(exit) SDL_RWclose(rwops);
        auto surface = SDL_Enforce(IMG_LoadPNG_RW(rwops)); // , "cannot load a file (only png supported): " ~ filename);
        scope(exit) SDL_FreeSurface(surface);
        this.rptr = r;
        this.ptr = SDL_Enforce(SDL_CreateTextureFromSurface(r, surface));
    }

    ~this() {
        SDL_DestroyTexture(this.ptr);
    }

    auto copy(const(SDL_Rect)* src, const(SDL_Rect)* dst,
              double angle=0.0, const(SDL_Point)* center=null, SDL_RendererFlip flip=SDL_FLIP_NONE) {
        SDL_RenderCopyEx(this.rptr, this.ptr, src, dst, angle, center, flip);
    }
}
