-- Configure database session collation
CreateThread(function()
  Wait(500)
  pcall(function() MySQL.query.await("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci") end)
  pcall(function() MySQL.query.await("SET collation_connection = 'utf8mb4_unicode_ci'") end)
  print("^2[SFW:DB] Session collation set to utf8mb4_unicode_ci^7")
end)
