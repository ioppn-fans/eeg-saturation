function stimmat = make_grating(pxsize, cycles, contr, orient, luminance, ~)

    [x, y] = meshgrid(linspace(-cycles*pi, cycles*pi, pxsize));
    [xlin, ylin] = meshgrid(linspace(-pxsize/2, pxsize/2, pxsize));
    
    x2 = x * cosd(orient); y2 = y * sind(orient);
    wave = luminance+ contr* luminance* cos((x2 + y2));
    
    fringe_width = 0.05*pxsize;
    
    alpha = zeros(size(x));
    
    n_loop = round(fringe_width);
    radii = linspace(pxsize/2-fringe_width, pxsize/2, n_loop);
    amplitudes = cos(linspace(0, 0.5*pi, n_loop));
    for irad = 1:n_loop
        radius = radii(irad);
        amp = amplitudes(irad);
        new_circ = amp*(sqrt(xlin.^2 + ylin.^2) < radius);
        alpha = max(alpha, new_circ);
    end
    
    
%     fringe_width = 0.6*centre_annul;
%     
%     alpha_centre = zeros(size(x));
%     
%     n_loop = round(fringe_width);
%     radii = linspace(centre_annul-fringe_width, centre_annul, n_loop);
%     amplitudes = cos(linspace(0, 0.5*pi, n_loop));
%     for irad = 1:n_loop
%         radius = radii(irad);
%         amp = amplitudes(irad);
%         new_circ = amp*(sqrt(xlin.^2 + ylin.^2) < radius);
%         alpha_centre = max(alpha_centre, new_circ);
%     end
%     alpha_centre = -alpha_centre + 1;
%     
    alpha = alpha  * 255;
    
    stimmat = cat(3, wave, wave, wave, alpha);
end
