; TODO:
; - Lizenshinweis
; - Anwendung auf Größe des aktuellen Layers oder auf gesamtes Bild

; define function
(define 
  (script-fu-photo-double-border-te
    img
    drawable
    border_color
    border_size
    passepartout_color
    passepartout_size
    use_real_shadows
    use_merge_layers
  )

  (let*
    (
      (save_color_foreground (car (gimp-context-get-foreground)))
      (save_color_background (car (gimp-context-get-background)))
      (img_width (car (gimp-image-width img)))
      (img_height (car (gimp-image-height img)))

      (use_passepartout FALSE)
      (use_border FALSE)
      (use_border_outside_shadow FALSE)

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
      (newLayer_border_Shadow_inside)
      (newLayer_border_Shadow_outside)
      (newLayer_passepartout)
      (newLayer_passepartout_Shadow)

      (new_mask)

      (color_black '(0 0 0))
      (color_white '(255 255 255))
      (shadow_color color_black)
    )

    ; ---------------------------------------------------------------
    ; create useful variables
    ; ---------------------------------------------------------------

    ; set borders to draw
    (if (> passepartout_size 0) (set! use_passepartout TRUE))
    (if (> border_size 0) (set! use_border TRUE))

    ; set outside shadow
    (if (= use_real_shadows TRUE) (set! use_border_outside_shadow TRUE))

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
        (script-fu-drop-shadow img newLayer_passepartout 0 0 5 shadow_color 20 FALSE)
        ; notice and rename new shadow layer
        ; TODO: - a little bit tricky?
        ;       - exclude in an extra function
        (set! newLayer_passepartout_Shadow 
          (aref 
            (cadr (gimp-image-get-layers img))
            (+ (car (gimp-image-get-layer-position img newLayer_passepartout)) 1)
          )
        )
        (gimp-drawable-set-name newLayer_passepartout_Shadow "Passepartout Shadow")

        ; resize shadow layer to image size
        (gimp-layer-resize-to-image-size newLayer_passepartout_Shadow)

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

        ; draw shadows
        (if (= use_real_shadows FALSE)
          ; draw drop shadow - simple
          (begin
            ; draw shadow inside and outside
            ; TODO: temporary hard coded
            (script-fu-drop-shadow img newLayer_border 0 0 10 shadow_color 80 FALSE)
            ; notice and rename new shadow layer
            ; TODO: - a little bit tricky?
            ;       - exclude in an extra function
            (set! newLayer_border_Shadow 
              (aref 
                (cadr (gimp-image-get-layers img))
                (+ (car (gimp-image-get-layer-position img newLayer_border)) 1)
              )
            )
            (gimp-drawable-set-name newLayer_border_Shadow "Border Shadow")
          )

          ; draw drop shadow - realistic
          (begin
            ; ----------------------------
            ; draw shadow inside
            ; ----------------------------

            ; TODO: temporary hard coded
            (script-fu-drop-shadow img newLayer_border 0 2 10 shadow_color 80 FALSE)

            ; notice and rename new shadow layer
            ; TODO: - a little bit tricky?
            ;       - exclude in an extra function
            (set! newLayer_border_Shadow_inside 
              (aref 
                (cadr (gimp-image-get-layers img))
                (+ (car (gimp-image-get-layer-position img newLayer_border)) 1)
              )
            )
            (gimp-drawable-set-name newLayer_border_Shadow_inside "Border Shadow (inside)")
            
            ; create mask
            (set! new_mask (car (gimp-layer-create-mask newLayer_border_Shadow_inside ADD-BLACK-MASK)))
            (gimp-layer-add-mask newLayer_border_Shadow_inside new_mask)
            (gimp-layer-get-edit-mask newLayer_border_Shadow_inside)
            ;(gimp-image-set-active-layer img newLayer_border_Shadow_inside)

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

            ; fill selection
            (gimp-context-set-background color_white)
            (gimp-edit-fill new_mask BACKGROUND-FILL)

            ; ...
            ;(gimp-image-set-active-layer img newLayer_border)

            ; ----------------------------
            ; draw shadow outside
            ; ----------------------------

            ; clear possible selections
            (gimp-selection-none img)

            ;
            (gimp-image-set-active-layer img newLayer_border)

            ; TODO: temporary hard coded
            (script-fu-drop-shadow img newLayer_border 0 4 15 shadow_color 80 FALSE)

            ; notice and rename new shadow layer
            ; TODO: - a little bit tricky?
            ;       - exclude in an extra function
            (set! newLayer_border_Shadow_outside 
              (aref 
                (cadr (gimp-image-get-layers img))
                (+ (car (gimp-image-get-layer-position img newLayer_border)) 1)
              )
            )
            (gimp-drawable-set-name newLayer_border_Shadow_outside "Border Shadow (outside)")
 
            ; create mask
            (set! new_mask (car (gimp-layer-create-mask newLayer_border_Shadow_outside ADD-WHITE-MASK)))
            (gimp-layer-add-mask newLayer_border_Shadow_outside new_mask)
            (gimp-layer-get-edit-mask newLayer_border_Shadow_outside)
            ;(gimp-image-set-active-layer img newLayer_border_Shadow_outside)

            ; create rectangle selection
            (gimp-rect-select
              img
              0 ;(- xPos passepartout_size)
              0 ;(- yPos passepartout_size)
              new_img_width
              new_img_height
              0 ;operation
              0 ;feather
              0 ;feather-radius
            )

            ; fill selection
            (gimp-context-set-background color_black)
            (gimp-edit-fill new_mask BACKGROUND-FILL)
          )
        )
      )
    )

    ; ---------------------------------------------------------------
    ; finish result (options)
    ; ---------------------------------------------------------------

    ; resize image to show outside shadow
    (if (= use_border_outside_shadow TRUE)
      (gimp-image-resize-to-layers img)
      ;(gimp-layer-resize-to-image-size newLayer_border)
    )

    ; merge result layers 
    (if (= use_merge_layers TRUE)
      (begin
        (if (= use_real_shadows FALSE)
          ; merge simple version
          (begin
            (set! newLayer_border (car (gimp-image-merge-down img newLayer_border EXPAND-AS-NECESSARY)))
            (set! newLayer_border (car (gimp-image-merge-down img newLayer_border EXPAND-AS-NECESSARY)))
            (set! newLayer_border (car (gimp-image-merge-down img newLayer_border EXPAND-AS-NECESSARY)))
          )
          ; merge realistic version
          (begin
            (set! newLayer_border (car (gimp-image-merge-down img newLayer_border EXPAND-AS-NECESSARY)))
            (set! newLayer_border (car (gimp-image-merge-down img newLayer_border EXPAND-AS-NECESSARY)))
            (set! newLayer_border (car (gimp-image-merge-down img newLayer_border EXPAND-AS-NECESSARY)))
            (set! newLayer_border (car (gimp-image-merge-down img newLayer_border EXPAND-AS-NECESSARY)))
          )
        )
        ; rename result layer
        (gimp-drawable-set-name newLayer_border "Border+Passepartout")
      )
    )

    ; ---------------------------------------------------------------
    ; reset gimp state
    ; ---------------------------------------------------------------

    ; clear forgotten selections
    (gimp-selection-none img)

    ; restore colors
    (gimp-context-set-foreground save_color_foreground)
    (gimp-context-set-background save_color_background)

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
    (if (= use_merge_layers TRUE)
      (list newLayer_border)
      ;(list newLayer_border newLayer_border_Shadow newLayer_passepartout newLayer_passepartout_Shadow)
    )
  )
)

; register function
(script-fu-register
  "script-fu-photo-double-border-te" ; function name
  "Doppelrahmen (Tigion Edition) ..." ; menu label
  "Creates a double border around a photo." ; description
  "Christoph Zirkelbach" ; author
  "Christoph Zirkelbach" ; copyright notice
  "November 9, 2008" ; date created
  "" ; image type that the script works on
  SF-IMAGE       "Image" 0
  SF-DRAWABLE    "Drawable" 0
  SF-COLOR       "Rahmenfarbe (außen)" '(0 0 0)
  SF-ADJUSTMENT  "Breite des Rahmens" '(10 1 1000 1 10 0 1)
  SF-COLOR       "Passepartoutfarbe (innen)" '(255 255 255)
  SF-ADJUSTMENT  "Breite des Passepartouts" '(20 0 1000 1 10 0 1)
  SF-TOGGLE      "Realistischere Schatten darstellen (auch ausserhalb)" FALSE
  SF-TOGGLE      "Ergebnislayer zusammenfassen" TRUE
)
(script-fu-menu-register "script-fu-photo-double-border-te" "<Image>/Script-Fu/Photo/")
