require 'date'
require 'yaml'

start_date = Date.new(2024, 01, 8)
end_date = Date.new(2024, 02, 16)

allowed_days_of_week = [1, 2, 4, 5]

day_list = []

current = start_date

while(current <= end_date)
  day_list << current

  current = current.next_day()
end

# keep those days we care about
day_list = day_list.keep_if { |d| allowed_days_of_week.include?(d.cwday()) }

current_week = 5
week = format('%s-%02d%s', "week", current_week, ".md")
day_list.each { |d|

  if(d.cwday() == 1)
    week = format('%s-%02d%s', "week", current_week, ".md")
    file = File.open(week, "w")

    header = ""
    header << "---\n"
    header << "title: \"Week #{format('%02d', current_week)}: Happy Monday!\"\n"
    header << "---\n\n"
    file.write(header)

    file.close()

    current_week = current_week + 1
  end

  file = File.open(week, "a")
  file.write(d.to_time.strftime("%b %d"))
  file.write("\n: To be announced\n")
  file.write("  : Material to be added\n\n")

  file.close()
}
