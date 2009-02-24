; define vignette function
(define (script-fu-photo-vignette img drawable color opacity f_radius f_strength)
  (let*
    (
      (saveForegroundColor (car (gimp-context-get-foreground)))
      (imgWidth   (car (gimp-image-width img)))
      (imgHeight  (car (gimp-image-height img)))

      (newWidth)
      (newHeight)
      (maxLength)
      (minLength) ; unused
      (buffer)
      (xPos)
      (yPos)

      (newLayer)
    )

    ; ---------------------------------------------------------------
    (gimp-undo-push-group-start img)
    ; ---------------------------------------------------------------

    ; check inputs
    (set! f_strength (- 100 f_strength))

    ; ---------------------------------------------------------------

    ; convert gray/indexed images to rgb color
    (if (= (car (gimp-drawable-is-rgb drawable)) FALSE)
      (gimp-image-convert-rgb img)
    )

    ; set foreground color to black
    (gimp-context-set-foreground color)
 
    ; get max/min length
    (if (< imgHeight imgWidth)
      (begin
        (set! maxLength imgWidth)
        (set! minLength imgHeight)
      )
      (begin
        (set! maxLength imgHeight)
        (set! minLength imgWidth)
      )
    )

    ; calc buffer
    (set! buffer (* maxLength (/ f_radius 100)))

    ; calc new size
    (if (>= buffer 0)
      (begin
        (set! newHeight (+ maxLength (* 2 buffer)))
        (set! newWidth  (+ maxLength (* 2 buffer)))
      )
      (begin
        (set! newHeight maxLength)
        (set! newWidth maxLength)
      )
    )    

    ; calc resize position
    (set! xPos (/ (- newWidth imgWidth) 2))
    (set! yPos (/ (- newHeight imgHeight) 2))

    ; ---------------------------------------------------------------
    
    ; resize to new size
    (gimp-image-resize img newWidth newHeight xPos yPos)

    ; create new layer
    (set! newLayer
      (car
        (gimp-layer-new
          img
          (car (gimp-image-width img))
          (car (gimp-image-height img))
          RGBA-IMAGE
          "Vignette"
          100
          NORMAL
        )
      )
    )
    (gimp-image-add-layer img newLayer -1)
    (gimp-selection-none img)
    (gimp-drawable-fill newLayer TRANSPARENT-FILL)

    ; ---------------------------------------------------------------

    ; create circle selection
    (gimp-ellipse-select
      img
      (abs (/ buffer 2))
      (abs (/ buffer 2))
      (+ maxLength buffer)
      (+ maxLength buffer)
      0 ;operation
      0 ;antialias-bool
      0 ;feather-bool
      0 ;feather-radius
    )
    
    ; invert selection
    (gimp-selection-invert img)

    ; ---------------------------------------------------------------

    ; fill selection with color
    (gimp-edit-fill newLayer FOREGROUND-FILL)
    (gimp-selection-clear img)
    
    ; Gaußscher Weichzeichner
    (if (> f_strength 0)
      (plug-in-gauss-rle 1 img newLayer (* maxLength (/ f_strength 100)) 1 1)
    )

    ; set layer opacity
    (gimp-layer-set-opacity newLayer opacity)

    ; ---------------------------------------------------------------

    ; restore default image size
    (gimp-image-resize img imgWidth imgHeight (- xPos) (- yPos))

    ; shrink layer to image size
    (gimp-layer-resize-to-image-size newLayer)

    ; restore colors
    (gimp-context-set-foreground saveForegroundColor)

    ; ---------------------------------------------------------------
    (gimp-undo-push-group-end img)
    ; ---------------------------------------------------------------

    ; display result
    (gimp-displays-flush img)

    ; return values
    (list img drawable newLayer)
  )
)

; register vignette function
(script-fu-register
  "script-fu-photo-vignette" ;func name
  "Vignettierung (Randabschattung) ..." ;menu label
  "Creates a vignette around a photo." ;description
  "Christoph Zirkelbach" ;author
  "Christoph Zirkelbach" ;copyright notice
  "July 21, 2008" ;date created
  "" ;image type that the script works on
  SF-IMAGE "Image" 0
  SF-DRAWABLE "Drawable" 0
  SF-COLOR       "Farbe"  '(0 0 0)
  SF-ADJUSTMENT  "Deckkraft" '(60 0 100 1 10 1 0)
  SF-ADJUSTMENT  "Radius" '(5 -75 25 1 10 0 0)
  SF-ADJUSTMENT  "Härte" '(75 0 100 1 10 0 0)
)
(script-fu-menu-register "script-fu-photo-vignette" "<Image>/Script-Fu/Photo/")
