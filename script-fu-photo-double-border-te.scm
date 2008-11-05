; TODO:
; [ ] Lizenshinweis

; define function
(define (script-fu-photo-double-border-te img drawable border_color border_size passepartout_color passepartout_size)
  (let*
    (
      (save_color_foreground (car (gimp-context-get-foreground)))
      (img_width (car (gimp-image-width img)))
      (img_height (car (gimp-image-height img)))

      (use_passepartout FALSE)
      (use_border FALSE)

      (new_img_width)
      (new_img_height)
      (select_width1) ; 1 = border
      (select_height1)
      (select_width2) ; 2 = passepartout
      (select_height2)
      (xPos 0)
      (yPos 0)

      (newLayer_border)
      (newLayer_border_Shadow)
      (newLayer_passepartout)
      (newLayer_passepartout_Shadow)
    )

    ; ---------------------------------------------------------------
    ; create useful variables
    ; ---------------------------------------------------------------

    ; set borders to draw
    (if (> passepartout_size 0) (set! use_passepartout TRUE))
    (if (> border_size 0) (set! use_border TRUE))

    ; calc new size
    (set! new_img_width  (+ img_width  (* 2 border_size) (* 2 passepartout_size)))
    (set! new_img_height (+ img_height (* 2 border_size) (* 2 passepartout_size)))

    ; calc selection for border
    (set! select_width1  (+ img_width  (* 2 passepartout_size)))
    (set! select_height1 (+ img_height (* 2 passepartout_size)))

    ; calc selection for passepartout
    (set! select_width2  img_width)
    (set! select_height2 img_height)

    ; calc resize position
    (set! xPos (+ border_size passepartout_size))
    (set! yPos (+ border_size passepartout_size))
 
    ; ---------------------------------------------------------------
    ; start point for undo group
    ; ---------------------------------------------------------------

    (gimp-undo-push-group-start img)

    ; ---------------------------------------------------------------
    ; clear and save gimp state
    ; ---------------------------------------------------------------

    ; set active layer
    (gimp-image-set-active-layer img drawable)

    ; clear possible selections
    (gimp-selection-none img)

    ; convert gray/indexed images to rgb color
    (if (= (car (gimp-drawable-is-rgb drawable)) FALSE)
      (gimp-image-convert-rgb img)
      ;(gimp-message "TODO: Hinweis ...")
    )

    ; ---------------------------------------------------------------
    ; prepare the image
    ; ---------------------------------------------------------------

    ; resize to new size
    (gimp-image-resize img new_img_width new_img_height xPos yPos)

    ; ---------------------------------------------------------------
    ; create passepartout
    ; ---------------------------------------------------------------

    (if (= use_passepartout TRUE)
      (begin
        ; create new layer for passepartout
        (set! newLayer_passepartout
          (car
            (gimp-layer-new
              img
              (car (gimp-image-width img))
              (car (gimp-image-height img))
              RGBA-IMAGE
              "Passepartout"
              100
              NORMAL
            )
          )
        )
        (gimp-image-add-layer img newLayer_passepartout -1)
        (gimp-drawable-fill newLayer_passepartout TRANSPARENT-FILL)

        ; create rectangle selection
        (gimp-rect-select
          img
          xPos
          yPos
          select_width2
          select_height2
          0 ;operation
          0 ;feather
          0 ;feather-radius
        )

        ; invert selection
        (gimp-selection-invert img)

        ; set foreground color to passepartout_color
        (gimp-context-set-foreground passepartout_color)

        ; fill selection with passepartout_color
        (gimp-edit-fill newLayer_passepartout FOREGROUND-FILL)
        
        ; clear selection
        (gimp-selection-none img)

        ; draw drop shadow
        ; TODO: temporary hard coded
        (script-fu-drop-shadow img newLayer_passepartout 0 0 5 '(0 0 0) 20 FALSE)
      )
    )

    ; ---------------------------------------------------------------
    ; create border
    ; ---------------------------------------------------------------

    (if (= use_border TRUE)
      (begin
        ; create new layer for border
        (set! newLayer_border
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
        (gimp-image-add-layer img newLayer_border -1)
        (gimp-drawable-fill newLayer_border TRANSPARENT-FILL)

        ; create rectangle selection
        (gimp-rect-select
          img
          (- xPos passepartout_size)
          (- yPos passepartout_size)
          select_width1
          select_height1
          0 ;operation
          0 ;feather
          0 ;feather-radius
        )
        
        ; invert selection
        (gimp-selection-invert img)

        ; set foreground color to border_color
        (gimp-context-set-foreground border_color)

        ; fill selection with border_color
        (gimp-edit-fill newLayer_border FOREGROUND-FILL)
      
        ; clear selection
        (gimp-selection-none img)

        ; draw drop shadow
        ; TODO: temporary hard coded
        (script-fu-drop-shadow img newLayer_border 0 0 10 '(0 0 0) 80 FALSE)
      )
    )

    ; ---------------------------------------------------------------
    ; reset gimp state
    ; ---------------------------------------------------------------

    ; clear forgotten selections
    (gimp-selection-none img)

    ; restore colors
    (gimp-context-set-foreground save_color_foreground)

    ; ---------------------------------------------------------------
    ; end point for undo group
    ; ---------------------------------------------------------------

    (gimp-undo-push-group-end img)
    
    ; ---------------------------------------------------------------
    ; finish
    ; ---------------------------------------------------------------

    ; display result
    (gimp-displays-flush img)

    ; return values
    (list newLayer_border newLayer_border_Shadow newLayer_passepartout newLayer_passepartout_Shadow)
  )
)

; register function
(script-fu-register
  "script-fu-photo-double-border-te" ; function name
  "Doppelrahmen (Tigion Edition) ..." ; menu label
  "Creates a double border around a photo." ; description
  "Christoph Zirkelbach" ; author
  "Christoph Zirkelbach" ; copyright notice
  "November 5, 2008" ; date created
  "" ; image type that the script works on
  SF-IMAGE       "Image" 0
  SF-DRAWABLE    "Drawable" 0
  SF-COLOR       "Rahmenfarbe (außen)" '(0 0 0)
  SF-ADJUSTMENT  "Breite des Rahmens" '(10 1 1000 1 10 0 1)
  SF-COLOR       "Passepartoutfarbe (innen)" '(255 255 255)
  SF-ADJUSTMENT  "Breite des Passepartouts" '(20 0 1000 1 10 0 1)
)
(script-fu-menu-register "script-fu-photo-double-border-te" "<Image>/Script-Fu/Photo/")

