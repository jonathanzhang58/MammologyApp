def zone(list_of_points):
    """
    returns the circle equations for a list of points
    [[centerx, centery, x point on circumference],...]
    """
    for i in list_of_points: 
        centerx = i[0]
        centery = i[1]
        radius = abs(i[0] - i[2])
        print(f"(x-{centerx})^2 + (y-{centery})^2 < {radius}^2")        

