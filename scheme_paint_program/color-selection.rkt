
#lang racket

;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;-*-*                                                                 *-*-
;-*-* Very basic drawing-program, mainly use: ASM-sprite development  *-*-
;-*-*                                                                 *-*-
;-*-*                          Aäron Munster                          *-*-
;-*-*              2018 Computerscience Second Bachelor               *-*-
;-*-*                   Vrije Universiteit Brussel                    *-*-
;-*-*                                                                 *-*-
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-

;; call the procedure give-sprite to get a sprite back.
;; the procedure should be called with a string which will be put in front of every line, e.g.: "DD "

;; ################################## THESE VALUES SHOULD BE CHANGED, NEXT IS THE CODE ################################## ;;

(define sprite-width                            20)
(define sprite-height                           20)
(define default-fillup-value               "0FFH");; not updated ( field will visually start blank! )
(define color-select-img-source "color-range.png");; swap with ohter value when desired ( other cell representation )

;; ################################### LET CODE BELOW AS IS TO ASSURE IT STILL WORKS #################################### ;;

(require racket/gui/base)

(define amount-of-colors-width  16); [0, 9] + [A, F] = 16
(define amount-of-colors-height 16); [0, 9] + [A, F] = 16

(define pixel-size 30)


(define (give-2D-vector width height default-value); vector filled with vectors, outer vector represents height
  (define outer-vector (make-vector height 'nothing))
  (do ([row 0 (+ row 1)])
    ((> row (- height 1)))
    (vector-set! outer-vector row (make-vector width default-value)))
  outer-vector)

(define sprite (give-2D-vector sprite-width
                               sprite-height
                               default-fillup-value))

(define color-selection-bitmap 'uninit)
(define selection-x            'uninit)
(define selection-y            'unitit)

(define (make-drawing-window)
  (define window (new frame% [label "Draw sprite here!!!!! VVVV"]))
  ;;; on this bitmap all 'new' cells will be drawn
  (define drawing-bitmap (make-object bitmap% min-width min-height))
  ;;; on this drawing-context the cells will be drawn
  (define draw-dc (new bitmap-dc% [bitmap drawing-bitmap]))
  (define (fill-canvas-with-cells)
    (do ((row 0 (+ row 1)))
      ((> row sprite-height))
      (do ((coll 0 (+ coll 1)))
        ((> coll sprite-width))
        ;; code that draws a cell
        (send draw-dc draw-rectangle
              (* coll pixel-size)
              (* row pixel-size)
              pixel-size
              pixel-size))))
  (fill-canvas-with-cells)
  ;;; this is the canvas-class which will be containing the sprite-bitmap;; handles the callback
  (define mouse-down #f)
  (define my-canvas% (class canvas%
                       (define/override (on-event mouse)
                         (when (send mouse button-down?)
                           (set! mouse-down #t))
                         (when mouse-down
                           ;; update sprite-vector:
                           (vector-set! (vector-ref sprite (floor (/ (send mouse get-y) pixel-size))) (floor (/ (send mouse get-x) pixel-size)) selected-color)
                           (send draw-dc draw-bitmap-section
                                 color-selection-bitmap
                                 (* pixel-size (floor (/ (send mouse get-x) pixel-size))); x
                                 (* pixel-size (floor (/ (send mouse get-y) pixel-size))); y
                                 selection-x
                                 selection-y
                                 pixel-size
                                 pixel-size))
                         (when (send mouse button-up?)
                           (set! mouse-down #f)))
                       (super-new)))

  ;; this is the effectively canvas
  (define canvas (new my-canvas%
                      [parent window]
                      [min-width (* sprite-width pixel-size)]
                      [min-height (* sprite-height pixel-size)]
                      [paint-callback
                       (lambda (canvas dc)
                         (set! draw-dc dc)
                         (send dc draw-bitmap drawing-bitmap 0 0))]))
  (send window show #t))

(define min-width (* amount-of-colors-width pixel-size))
(define min-height (* amount-of-colors-height pixel-size))

(define color-list (make-vector #| 0 tot F |# 16 (make-vector 16 #f))) ;; eerst de y-waarde, daarna de x-waarde

(define string-list (list "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F"))

(define (fill-up)
  (do ([row 0 (+ row 1)])
    ((> row 15))
    (vector-set! color-list row (make-vector 16 'empty))
    (do ([coll 0 (+ coll 1)])
      ((> coll 15))
      (vector-set! (vector-ref color-list row) coll (string-append "0" (list-ref string-list row) (list-ref string-list coll) "H" )))))

(fill-up)
color-list

(define selected-color 'none-yet)

(define (make-color-select)
  (define window (new frame% [label "Select color here!!! VVVV"]))
  (define drawing-bitmap (make-object bitmap% min-width min-height))
  (send drawing-bitmap load-file color-select-img-source 'png)
  (define my-canvas% (class canvas% (define/override (on-event mouse)
                                      (when (send mouse button-down?)
                                        (set! selection-x (+ (* pixel-size (floor (/ (send mouse get-x) pixel-size))) 1))
                                        (set! selection-y (* pixel-size (floor (/ (send mouse get-y) pixel-size))))
                                        (set! selected-color (vector-ref (vector-ref color-list (floor (/ (send mouse get-y) pixel-size)))
                                                                         (floor (/ (send mouse get-x) pixel-size))))
                                        (display selected-color)))
                       ;(display (~a "You clicked this x: " (floor (/ (send mouse get-x) pixel-size)) " and this y: " (floor (/ (send mouse get-y) pixel-size)) "\n"))
                       (super-new)))
  (define canvas (new my-canvas%
                      [parent window]
                      [min-width min-width]
                      [min-height min-height]
                      [paint-callback
                       (lambda (canvas dc)
                         (set! color-selection-bitmap drawing-bitmap)
                         (send dc draw-bitmap drawing-bitmap 0 0))]))
  (send window show #t))

(define select-color   (make-color-select))
(define make-drawing (make-drawing-window))

(define (give-sprite this-in-front-of-everything-please)
  (do ((row 0 (+ row 1)))
    ((> row (- sprite-height 1)))
    (display this-in-front-of-everything-please)(display " ")
    (do ((coll 0 (+ coll 1)))
      ((> coll (- sprite-width 1)))
      (display (vector-ref (vector-ref sprite row) coll))(unless (= coll (- sprite-width 1))(display ", ")))
    (newline)))