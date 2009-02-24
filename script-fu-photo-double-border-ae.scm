; define double border ae function
(define (script-fu-photo-double-border-ae img drawable color1 border1 color2 border2 offset_type offset_width cut_type use_inside use_blur blur_strength)
  (let*
    (
      (saveForegroundColor (car (gimp-context-get-foreground)))
      (imgWidth   (car (gimp-image-width img)))
      (imgHeight  (car (gimp-image-height img)))

      (newWidth)
      (newHeight)
      (selectWidth1)
      (selectHeight1)
      (selectWidth2)
      (selectHeight2)
      (xPos 0)
      (yPos 0)

      (newLayer)
    )

    ; ---------------------------------------------------------------
    (gimp-undo-push-group-start img)
    ; ---------------------------------------------------------------
    
    ; check inputs
    (if (= use_blur TRUE)
      (set! use_inside TRUE)
    )

    ; ---------------------------------------------------------------

    ; convert gray/indexed images to rgb color
    (if (= (car (gimp-drawable-is-rgb drawable)) FALSE)
      (gimp-image-convert-rgb img)
    )

    ; calc new size
    (set! newWidth  (+ imgWidth  (* 2 border1) (* 2 border2)))
    (set! newHeight (+ imgHeight (* 2 border1) (* 2 border2)))

    ; calc selects for outside or inside border
    (if (= use_inside FALSE)
      ; border outside
      (begin
        (set! selectWidth1  (+ imgWidth  (* 2 border2)))
        (set! selectHeight1 (+ imgHeight (* 2 border2)))
        (set! selectWidth2  imgWidth)
        (set! selectHeight2 imgHeight)
      )

      ; border inside
      (begin
        (set! selectWidth1  (- imgWidth  (* 2 border1)))
        (set! selectHeight1 (- imgHeight (* 2 border1)))
        (set! selectWidth2  (- imgWidth  (* 2 border1) (* 2 border2)))
        (set! selectHeight2 (- imgHeight (* 2 border1) (* 2 border2)))
      )
    )

    ; calc resize position
    (set! xPos (+ border1 border2))
    (set! yPos (+ border1 border2))
   
    ; correct new size and resize position for offset_width
    (if (= offset_type 1) ; left
      (begin
        (set! newWidth (+ newWidth offset_width))
        (set! xPos (+ xPos offset_width))

        ; corrections for inside border
        (if (= use_inside TRUE)
          (begin
           (set! selectWidth1 (- selectWidth1 offset_width))
           (set! selectWidth2 (- selectWidth2 offset_width))
          )
        )
      )
    )
    (if (= offset_type 2) ; top
      (begin
        (set! newHeight (+ newHeight offset_width))
        (set! yPos (+ yPos offset_width))

        ; corrections for inside border
        (if (= use_inside TRUE)
          (begin
           (set! selectHeight1 (- selectHeight1 offset_width))
           (set! selectHeight2 (- selectHeight2 offset_width))
          )
        )
      )
    )
    (if (= offset_type 3) ; right
      (begin
        (set! newWidth (+ newWidth offset_width))

        ; corrections for inside border
        (if (= use_inside TRUE)
          (begin
            (set! selectWidth1 (- selectWidth1 offset_width))
            (set! selectWidth2 (- selectWidth2 offset_width))
          )
        )
      )
    )
    (if (= offset_type 4) ; bottom
      (begin
        (set! newHeight (+ newHeight offset_width))

        ; corrections for inside border
        (if (= use_inside TRUE)
          (begin
            (set! selectHeight1 (- selectHeight1 offset_width))
            (set! selectHeight2 (- selectHeight2 offset_width))
          )
        )
      )
    )
    (if (= offset_type 5) ; horizontal
      (begin
        (set! newWidth (+ newWidth (* 2 offset_width)))
        (set! xPos (+ xPos offset_width))

        ; corrections for inside border
        (if (= use_inside TRUE)
          (begin
            (set! selectWidth1 (- selectWidth1 (* 2 offset_width)))
            (set! selectWidth2 (- selectWidth2 (* 2 offset_width)))
          )
        )
      )
    )
    (if (= offset_type 6) ; vertical
      (begin
        (set! newHeight (+ newHeight (* 2 offset_width)))
        (set! yPos (+ yPos offset_width))

        ; corrections for inside border
        (if (= use_inside TRUE)
          (begin
           (set! selectHeight1 (- selectHeight1 (* 2 offset_width)))
           (set! selectHeight2 (- selectHeight2 (* 2 offset_width)))
          )
        )
      )
    )

    ; ---------------------------------------------------------------
    
    ; resize to new size
    (if (= use_inside FALSE)
      (gimp-image-resize img newWidth newHeight xPos yPos)
    )

    ; clear selection
    (gimp-selection-none img)

    ; create new layer
    (if (= use_blur FALSE)
      ; color border
      (begin
        (set! newLayer
          (car
            (gimp-layer-new
              img
              (car (gimp-image-width img))
              (car (gimp-image-height img))
              RGBA-IMAGE
              "Border"
              100
              NORMAL
            )
          )
        )
        (gimp-image-add-layer img newLayer -1)
        (gimp-drawable-fill newLayer TRANSPARENT-FILL)
      )

      ; blur border
      (begin
        (set! newLayer (car (gimp-layer-copy drawable TRUE)))
        (gimp-drawable-set-name newLayer "Border")
        (gimp-layer-set-opacity newLayer 100)
        (gimp-image-add-layer img newLayer -1)

        ; Gaußscher Weichzeichner
        (if (> blur_strength 0)
          (plug-in-gauss-rle 1 img newLayer blur_strength 1 1)
        )
      )
    )

    ; ---------------------------------------------------------------

    ; create rectangle selection 1
    (gimp-rect-select
      img
      (- xPos border2)
      (- yPos border2)
      selectWidth1
      selectHeight1
      0 ;operation
      0 ;feather
      0 ;feather-radius
    )
    
    ; creat border color or blur
    (if (= use_blur FALSE)
      ; use color Border
      (begin
        ; invert selection 1
        (gimp-selection-invert img)

        ; set foreground color to color1
        (gimp-context-set-foreground color1)

        ; fill selection 1 with color1
        (gimp-edit-fill newLayer FOREGROUND-FILL)
      )

      ; use blur border
      (begin
        ; cut selection
        (gimp-edit-cut newLayer)
      )
    )
  
    ; clear selection
    (gimp-selection-none img)

    ; ---------------------------------------------------------------

    ; create border 2
    (if (> border2 0)
      (begin
        ; create rectangle selection 2
        (gimp-rect-select
          img
          (- xPos border2)
          (- yPos border2)
          selectWidth1
          selectHeight1
          0 ;operation
          0 ;feather
          0 ;feather-radius
        )

        (gimp-rect-select
          img
          xPos
          yPos
          selectWidth2
          selectHeight2
          1 ;operation
          0 ;feather
          0 ;feather-radius
        )

        ; set foreground color to color2
        (gimp-context-set-foreground color2)

        ; fill selection 2 with color2
        (gimp-edit-fill newLayer FOREGROUND-FILL)
        (gimp-selection-clear img)
      )
    )

    ; ---------------------------------------------------------------
    
    ; cut borders to new image size
    (if (= cut_type 1) ; horizontal
      (begin
        (if (= use_inside FALSE)
          ; outside
          (gimp-image-resize img newWidth imgHeight 0 (- yPos))

          ; inside
          (gimp-image-resize img imgWidth selectHeight2 0 (- yPos))
        )

        ; cut (resize)
        (gimp-layer-resize-to-image-size newLayer)
      )
    )
    (if (= cut_type 2) ; vertical
      (begin
        (if (= use_inside FALSE)
          ; outside
          (gimp-image-resize img imgWidth newHeight (- xPos) 0)

          ; inside
          (gimp-image-resize img selectWidth2 imgHeight (- xPos) 0)
        )

        ; cut (resize)
        (gimp-layer-resize-to-image-size newLayer)
      )
    )

    ; ---------------------------------------------------------------

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
  "script-fu-photo-double-border-ae" ;func name
  "Doppelrahmen (Anticeye Edition) ..." ;menu label
  "Creates a double border around a photo." ;description
  "Christoph Zirkelbach" ;author
  "Christoph Zirkelbach" ;copyright notice
  "July 21, 2008" ;date created
  "" ;image type that the script works on
  SF-IMAGE    "Image" 0
  SF-DRAWABLE "Drawable" 0
  SF-COLOR       "Rahmenfarbe außen" '(0 0 0)
  SF-ADJUSTMENT  "Breite des Rahmens" '(20 1 1000 1 10 0 1)
  SF-COLOR       "Rahmenfarbe innen" '(255 255 255)
  SF-ADJUSTMENT  "Breite des Rahmens" '(1 0 1000 1 10 0 1)
  SF-OPTION      "Rahmenausdehnung" (mapcar car '(
      ("keine"             0) ; none
      ("nach links"        1) ; left
      ("nach oben"         2) ; top
      ("nach rechts"       3) ; right
      ("nach unten"        4) ; bottom
      ("mittig horizontal" 5) ; horizontal
      ("mittig vertikal"   6) ; vertical
    )
  )
  SF-ADJUSTMENT  "Breite der Rahmenausdehnung" '(20 1 1000 1 10 0 1)
  SF-OPTION      "Rahmenbeschnitt" (mapcar car '(
      ("keinen"                      0) ; none
      ("horizontal (oben und unten)" 1) ; horizontal (cut top and bottom border)
      ("vertikal (links und rechts)" 2) ; vertical (cut left and right border)
    )
  )
  SF-TOGGLE      "Rahmen innerhalb des Bildes anlegen. (Sichtbarer Bereich des Bildes wird kleiner!)" FALSE
  SF-TOGGLE      "Statt des äußeren Rahmens einen nach innen gesetzten unscharfen Glasrahmen verwenden." FALSE
  SF-ADJUSTMENT  "Unschärfe des Glasrahmens" '(20 0 100 1 10 0 0)
)
(script-fu-menu-register "script-fu-photo-double-border-ae" "<Image>/Script-Fu/Photo/")
