def zone(list_of_points, number):
   """
   Returns a MATLAB function string for a list of points
   [[centerx, centery, x point on circumference, y point on circumference],...]
   """
   digit_names = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
   number_name = "zero"+"".join(digit_names[int(digit)] for digit in str(number))
   function_name = f"{number_name}_CCMLO_wbenign"
   result = f"function result1 = {function_name}(x , y)\n"
   result += "    if "
   
   for idx, i in enumerate(list_of_points):
      centerx = i[0]
      centery = i[1]
      radius_x = abs(i[0] - i[2])  # Semi-major axis
      radius_y = abs(i[1] - i[3])  # Semi-minor axis
      result += f"((x-{centerx})^2 / {radius_x}^2) + ((y-{centery})^2 / {radius_y}^2) < 1"
      if idx != len(list_of_points) - 1:
         result += " || ...\n"
      else:
         result += "\n"
   
   result += "        result1 = true;\n"
   result += "    else\n"  
   result += "        result1 = false;\n"
   result += "    end\n"
   result += "end\n"
   
   print(f"funcStruct('Images/{number:03d}_CCMLO_wbenign.jpg') = "
         f"{{@(x, y) {number_name}_CCMLO_wbenign(x, y),"
         f'"Answers/{number:03d}_CCMLO_wannot.jpg", "category3 (image 3-4)"}};\n')
   
   return result


# print(zone([[24.02,16.08,20.94,22.76]], 1000277))
print(zone([[10.38,16.69,8.02,21.38],[36.67,20.6,33.91,26.33]], 1000290))
# print(zone([[11.11,38.54,6.87,45.66],[45.05,5.66,6.03,11.51],[43.23,28.86,39.4,35.62]], 1000236))
# print(zone([[3.11,12.44,0.56,17.36],[37.85,18.46,35.52,21.76],[2.83,43.88,0,47.74],[38.35,52.53,34.91,56.94]], 1000087))
