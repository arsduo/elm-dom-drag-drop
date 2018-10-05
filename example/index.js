// index.js
"use strict";

import { Elm } from "./MovableObjects.elm";
const mountNode = document.getElementById("elm-app");
const app = Elm.MovableObjects.init({ node: mountNode });

document.body.addEventListener("dragstart", event => {
  if (event.target && event.target.draggable) {
    // absurdly, this is needed for Firefox; see https://medium.com/elm-shorts/elm-drag-and-drop-game-630205556d2
    event.dataTransfer.setData("text/html", "blank");
  }
});

document.body.addEventListener("dragover", event => {
  // this is needed in order to make dragging work
  return false;
});
