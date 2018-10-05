// index.js
"use strict";

import Elm from "./MovableObjects.elm";
const mountNode = document.getElementById("elm-app");
const app = Elm.Stuff.embed(mountNode);
