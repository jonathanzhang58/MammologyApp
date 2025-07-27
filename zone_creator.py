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
         f'"Answers/{number:03d}_CCMLO_wannot.jpg", "category3 (image 3-4)"}};')
   
   return result


# print(zone([[20,16,18,19]], 152))
print(zone([[44,37,41,41],[9.1,18,6.1,22]], 177 ))
# print(zone([[56,34,50,46],[23,37,19,45],[23,20, 19, 26]], 118))
# print(zone([[4,45,47,49],[51,49,50,52],[17,37,15,42],[19,42,18,45]], 168))
