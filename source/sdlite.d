module sdlite;

import std.format : format;
import std.exception : enforce;
import std.stdio : writeln;
import std.string : toStringz;
import std.traits : isPointer;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

auto SDL_Enforce(SDL_bool cond, string reason="") {
    enforce(cond == SDL_TRUE,
            format!"%s (%d: %s)"(reason, cond, SDL_GetError()));
}

auto SDL_Enforce(T)(T ptr, string reason="") if (isPointer!T || is(T == bool)) {
    return enforce(ptr, format!"%s (%s)"(reason, SDL_GetError()));
}

struct Window {
    SDL_Window* ptr;

    this(string title, int width, int height,
         int x=SDL_WINDOWPOS_CENTERED,
         int y=SDL_WINDOWPOS_CENTERED,
         SDL_WindowFlags flags=SDL_WINDOW_SHOWN
        ) {
        this.ptr = SDL_Enforce(
            SDL_CreateWindow(title.toStringz, x, y, width, height, flags),
            "Window could not be created"
            );
    }

    ~this() {
        SDL_DestroyWindow(this.ptr);
    }

    auto renderer() {
        return Renderer(this.ptr);
    }
}

struct Renderer {
    SDL_Renderer* ptr;

    this(SDL_Window* window, int index=-1,
         SDL_RendererFlags flags=SDL_RENDERER_ACCELERATED // the renderer uses hardware acceleration
         | SDL_RENDERER_PRESENTVSYNC  // present is synchronized with the refresh rate
        ) {
        this.ptr = SDL_Enforce(SDL_CreateRenderer(window, index, flags),
                               "Renderer could not be created");
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

    auto loadTexture(string filename) {
        return Texture(this.ptr, filename);
    }
}

struct Event {
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
    SDL_Texture* ptr;
    SDL_Renderer* rptr;
    this(SDL_Renderer* r, string filename) {
        auto rwops = SDL_Enforce(SDL_RWFromFile(filename.toStringz, "rb"), "cannot load a file: " ~ filename);
        scope(exit) SDL_RWclose(rwops);
        auto surface = SDL_Enforce(IMG_LoadPNG_RW(rwops), "cannot load a file (only png supported): " ~ filename);
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

