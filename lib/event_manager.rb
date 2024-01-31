require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.to_s.tr("^0-9", "")
  if phone_number.length < 10 || phone_number.length > 11
    "Invalid phone number"
  elsif phone_number.length == 10
    phone_number
  elsif phone_number.length == 11
    if phone_number[0] == 1
      phone_number.slice(1..phone_number.length - 1)
    else
      "Invalid phone number"
    end
  end
end

def get_hour_of_reg(time)
  time.split[1].rjust(5, "0")[0..1]
end

def get_date_of_reg(date)
  day_of_week_num = Date.strptime(date, "%m/%d/%y").wday
  day_of_week_name = Date::DAYNAMES[day_of_week_num]
end

def get_best_time_for_ads(hours)
  sorted_times = hours.sort_by{ |key, value| value }.reverse
  puts "The best hours to place ads are in the #{sorted_times[0][0]}:00 hour and the #{sorted_times[1][0]}:00 hour."
end

def get_best_day_for_ads(days)
  sorted_days = days.sort_by{ |key, value| value }.reverse
  puts "The best day to place ads is #{sorted_days[0][0]} with #{sorted_days[0][1]} registrations, followed by #{sorted_days[1][0]} with #{sorted_days[1][1]} registrations."
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager initialized.\n\s"

contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new(template_letter)

hours_of_reg = {}
days_of_reg = {}
contents.each do |row|
  id = row[0]

  name = row[:first_name]

  day_of_week_name = get_date_of_reg(row[:regdate].split[0])
  days_of_reg.has_key?(day_of_week_name) ? days_of_reg[day_of_week_name] += 1 : days_of_reg[day_of_week_name] = 1

  hour = get_hour_of_reg(row[:regdate])
  hours_of_reg.has_key?(hour) ? hours_of_reg[hour] += 1 : hours_of_reg[hour] = 1

  phone_number = clean_phone_number(row[:homephone])

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id, form_letter)
end

get_best_time_for_ads(hours_of_reg)
get_best_day_for_ads(days_of_reg)