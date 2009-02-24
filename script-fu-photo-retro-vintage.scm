; define vignette function
(define (script-fu-photo-retro-vintage img drawable red green blue use_colorize color1 opacity1 use_color_overlay color2 opacity2 use_merge)
  (let*
    (
      (saveForegroundColor (car (gimp-context-get-foreground)))
      (imgWidth   (car (gimp-image-width img)))
      (imgHeight  (car (gimp-image-height img)))

      (spline_red   (cons-array 6 'byte))
      (spline_green (cons-array 8 'byte))
      (spline_blue  (cons-array 8 'byte))

      (newLayer)
      (newLayer1)
      (newLayer2)
      (newLayer3)

      (r (car color1))
      (g (cadr color1))
      (b (caddr color1))
      (factor)
      (hue 0)
    )

    ; ---------------------------------------------------------------

    ; check inputs
    ; nothing to do

    ; ---------------------------------------------------------------

    ; set curve points - red
    (aset spline_red 0   0) (aset spline_red 1   0)
    (aset spline_red 2 100) (aset spline_red 3 (+ 100 red)) ;75
    (aset spline_red 4 255) (aset spline_red 5 255)

    ; set curve points - green
    (aset spline_green 0   0) (aset spline_green 1   0)
    (aset spline_green 2  85) (aset spline_green 3  85)
    (aset spline_green 4 190) (aset spline_green 5 (+ 190 green)) ;200
    (aset spline_green 6 255) (aset spline_green 7 255)

    ; set curve points - blue
    (aset spline_blue 0   0) (aset spline_blue 1   0)
    (aset spline_blue 2   0) (aset spline_blue 3 (+ 0 blue)) ;25
    (aset spline_blue 4 255) (aset spline_blue 5 (- 255 blue)) ;230
    (aset spline_blue 6 255) (aset spline_blue 7 255)

    ; ---------------------------------------------------------------
    (gimp-undo-push-group-start img)
    ; ---------------------------------------------------------------

    ; check visibility
    (if (= (car (gimp-drawable-get-visible drawable)) FALSE)
      (begin
        (gimp-message "Der Filter kann nur auf sichtbare Ebenen angewendet werden, weswegen die Sichtabrkeit der Quellebene geändert wurde!")
        (gimp-drawable-set-visible drawable TRUE)
      )
    )

    ; convert gray/indexed images to rgb color
    (if (= (car (gimp-drawable-is-rgb drawable)) FALSE)
      (gimp-image-convert-rgb img)
    )

    ; ---------------------------------------------------------------
    ; create curve layer
    ; ---------------------------------------------------------------

    ; clear selection
    (gimp-selection-none img)

    ; copy photo layer
    (set! newLayer (car (gimp-layer-copy drawable TRUE)))
    (gimp-drawable-set-name newLayer "Adjust Color Curves")
    (gimp-layer-set-opacity newLayer 100)
    (gimp-image-add-layer img newLayer -1)

    ; set curves
    (gimp-curves-spline newLayer HISTOGRAM-RED   6 spline_red)
    (gimp-curves-spline newLayer HISTOGRAM-GREEN 8 spline_green)
    (gimp-curves-spline newLayer HISTOGRAM-BLUE  8 spline_blue)

    ; ---------------------------------------------------------------
    ; create colorize layer
    ; ---------------------------------------------------------------

    (if (= use_colorize TRUE)
      (begin
        ; copy curves layer
        (set! newLayer1 (car (gimp-layer-copy drawable TRUE)))
        (gimp-drawable-set-name newLayer1 "Colorize")
        (gimp-layer-set-opacity newLayer1 opacity1)
        (gimp-image-add-layer img newLayer1 -1)

        ; calc color hue
        (if (> r (and g b))
          (begin ; red
            (if (> g b)
              (begin
                (set! factor (/ (- r b) 60))
                (set! hue (/ (- g b) factor))
              )
              (begin
                (set! factor (/ (- r g) 60))
                (set! hue (/ (+ g (- (* 360 factor) b)) factor))
              )
            )
          )
        )
        (if (> g (and r b))
          (begin ; green
            (if (> r b)
              (set! factor (/ (- g b) 60))
              (set! factor (/ (- g r) 60))
            )
            (set! hue (/ (+ (- (* 120 factor) r) b) factor))
          )
        )
        (if (> b (and r g))
          (begin ; blue
            (if (> r g)
              (set! factor (/ (- b g) 60))
              (set! factor (/ (- b r) 60))
            )
            (set! hue (/ (- (+ (* 240 factor) r) g) factor))
          )
        )            

        ; check color hue
        (if (< hue 0)
          (set! hue 0)
        )
        (if (> hue 360)
          (set! hue 360)
        )

        ; colorize
        (gimp-colorize newLayer1 hue 50 20)
      )
    )

    ; ---------------------------------------------------------------
    ; create color overlay layer
    ; ---------------------------------------------------------------
    
    (if (= use_color_overlay TRUE)
      (begin
        ; set foreground color
        (gimp-context-set-foreground color2)

        ; create new layer
        (set! newLayer2
          (car
            (gimp-layer-new
              img
              (car (gimp-image-width img))
              (car (gimp-image-height img))
              RGBA-IMAGE
              "Color Overlay"
              opacity2
              NORMAL
            )
          )
        )
        (gimp-image-add-layer img newLayer2 -1)
        (gimp-drawable-fill newLayer2 FOREGROUND-FILL)
      )
    )

    ; ---------------------------------------------------------------

    ; merge new layers
    (if (= use_merge TRUE)
      (begin
        ; layer: color overlay
        (if (= use_color_overlay TRUE)
          (set! newLayer2 (car (gimp-image-merge-down img newLayer2 EXPAND-AS-NECESSARY))) ; newLayer2
          (set! newLayer2 newLayer1)
        )
        
        ; layer: colorize
        (if (= use_colorize TRUE)
          (set! newLayer2 (car (gimp-image-merge-down img newLayer2 EXPAND-AS-NECESSARY))) ; newLayer1
          (begin
            (if (= use_color_overlay FALSE)
              (set! newLayer2 newLayer)
            )
          )
        )
        
        ; layer: adjusted color curves
        (set! drawable (car (gimp-image-merge-down img newLayer2 EXPAND-AS-NECESSARY))) ; newLayer
        (gimp-drawable-set-name drawable "Retro Vintage Effect")
      )
    )

    ; restore colors
    (gimp-context-set-foreground saveForegroundColor)

    ; ---------------------------------------------------------------
    (gimp-undo-push-group-end img)
    ; ---------------------------------------------------------------

    ; display result
    (gimp-displays-flush img)

    ; return values
    ;(list img drawable)
  )
)

; register retro-vintage function
(script-fu-register
  "script-fu-photo-retro-vintage" ;func name
  "Vintage Retroeffekt ..." ;menu label
  "Creates a retro vintage effect." ;description
  "Christoph Zirkelbach" ;author
  "Christoph Zirkelbach" ;copyright notice
  "July 23, 2008" ;date created
  "" ;image type that the script works on
  SF-IMAGE "Image" 0
  SF-DRAWABLE "Drawable" 0
  SF-ADJUSTMENT  "Rotanteil im dunklen Bereich"  '(-25 -100 155 1 10 0 0)
  SF-ADJUSTMENT  "Grünanteil im hellen Bereich" '( 10 -190 65 1 10 0 0)
  SF-ADJUSTMENT  "Blauanteil im dunklen und hellen Bereich" '( 25  0 255 1 10 0 0)
  SF-TOGGLE      "Einfärbung verwenden. (Hinweis: Die gewählte Farbe dient zur Ermittlung des Farbtones.)" TRUE
  SF-COLOR       "Farbe der Einfärbung"  '(255 213 0)
  SF-ADJUSTMENT  "Deckkraft der Einfärbung"  '(40 0 100 1 10 0 0)
  SF-TOGGLE      "Korrekturfarbstich verwenden." TRUE
  SF-COLOR       "Farbe des Farbstichs"  '(255 0 255)
  SF-ADJUSTMENT  "Deckkraft des Farbstichs"  '(5 0 100 1 10 0 0)
  SF-TOGGLE      "Ergebnisse zusammenfassen." TRUE
)
(script-fu-menu-register "script-fu-photo-retro-vintage" "<Image>/Script-Fu/Photo/")
