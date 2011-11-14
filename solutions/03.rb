require 'bigdecimal'
require 'bigdecimal/util'

class Inventory
  attr_reader :product
  attr_reader :coupon

  def initialize
    @product = []
    @coupon = {}
  end

  def register(name, price, promotion = {})
    if check_duplicate_name? name
      @product << Product.new(name, price, check_register_promotion?(promotion))
    end
  end

  def check_duplicate_name?(name)
    product.each do |x|
      if x.name == name then raise "Diplicate product!" else return true end
    end
  end

  def check_register_promotion?(promo)
    case promo.keys.first
      when :get_one_free then GetOneFreePromotion.new promo[:get_one_free]
      when :package then PackagePromotion.new promo[:package]
      when :threshold then ThresholdPromotion.new promo[:threshold]
      else NoPromotion.new
    end
  end

  def register_coupon(name = "", kind = {})
    if kind.has_key? :amount
      @coupon[name.upcase] = Coupon.new.register(name.upcase, kind)
    end
    if kind.has_key? :percent
      @coupon[name.upcase] = Coupon.new.register(name.upcase, kind)
    end
    if name == ""
      @coupon[""] = NoCoupon.new
    end
 end

  def new_cart
    register_coupon
    Cart.new product, coupon
  end
end

class Product
  attr_reader :name
  attr_reader :price
  attr_reader :promotion

  def initialize(name, price, promotion = {})
    if name.length <= 40
      @name = name
    else
      raise "Invalid product name(<= 40 chars)!"
    end
    if ((price.to_f > 0)and(price.to_f <=999.99))
      @price = price.to_d
    else
      raise "Invalid price(0 < price <= 999.99)"
    end
    @promotion = promotion
  end
end

class Cart
  attr_reader :inventory
  attr_reader :coupon
  attr_reader :items
  attr_reader :used_coupon

  def initialize(inv, coupon)
    @inventory = inv
    @coupon = coupon
    @items = {}
    @used_coupon = false
  end

  def add(name, qty = 1)
    item = check_add_name name
    if items[item] == nil
      add_item_nil item, qty
    else
      add_item item, qty
    end
  end

  def check_add_name(name)
    inventory.each do |item|
      if item.name == name
        return item
      end
    end
    raise "No such product in inventory!"
  end

  def add_item_nil(item, qty)
    if qty>0 and qty<=99
      items[item] = qty
    else
      raise "Product quantity can`t be under 0 and over 99!"
    end
  end

  def add_item(item, qty = 1)
    if (items[item] + qty)>0 and (items[item] + qty)<=99
      items[item] = items[item]+ qty
    else
      raise "Product quantity can`t be under 0 and over 99!"
    end
  end

  def use(name)
    @used_coupon = true
  end

  def total
    total = 0
    coupon_disc = 0
    items.each do |item, qty|
      total += item.price*qty - item.promotion.discount(item, qty)
    end
    if used_coupon == true
      coupon_disc = coupon.values[0].discount total
    else
      0
    end
    return (total - coupon_disc)
  end

  def invoice
    Invoice.new(total, coupon, items).print
  end
end

class Invoice
  attr_reader :total
  attr_reader :coupon
  attr_reader :items
  attr_reader :invoice

  def initialize(total, coupon, items)
    @total = total
    @coupon = coupon
    @items = items
    @invoice = ""
  end

  def header
    output = "+#{"-"*48}+----------+
| Name#{" "*39}qty |    price |
+#{"-"*48}+----------+\n"
    return output
  end

  def middle
    sum= 0
    output = ""
    items.each do |item, qty|
      sum = (item.price * qty).to_f
      name = item.name
      output << "| #{name.ljust(44)+qty.to_s.rjust(2)} |"+("%.2f" % sum).rjust(9)+" |\n"
      output << item.promotion.line
    end
    return output << coupon.values[0].line
  end

  def footer
    output ="+#{"-"*48}+----------+
| TOTAL#{" "*42}|#{(" %.2f" % total.to_s).rjust(9) + " |"}
+#{"-"*48}+----------+\n"
  end

  def print
    invoice << header
    invoice << middle
    invoice << footer
    return invoice
  end
end

class NoPromotion
  def discount(item = 0, i_qty = 0)
    0
  end

  def line
    ""
  end
end

class GetOneFreePromotion
  attr_reader :qty
  attr_reader :result

  def initialize(qty)
    @qty = qty
    @result = 0
  end

  def discount(item, i_qty)
    @result = (i_qty/qty)*item.price
    return result
  end

  def line
    "|   (buy #{qty - 1}, get 1 free)#{" "*26}|"+("-%.2f" % result).rjust(9)+" |\n"
  end
end

class PackagePromotion
  attr_reader :pack
  attr_reader :percent
  attr_reader :result

  def initialize(package)
    @pack = package.keys[0]
    @percent = package.values[0]
    @result = 0
  end

  def discount(item, i_qty)
    @result = (i_qty/pack)*pack*item.price*(percent/100.0)
    return result
  end

  def line
    output = "|   (get #{percent}% off for every #{pack})#{" "*20}|"
    return output+("-%.2f" % result).rjust(9)+" |\n"
  end
end

class ThresholdPromotion
  attr_reader :qty
  attr_reader :percent
  attr_reader :result

  def initialize(threshold)
    @qty = threshold.keys[0]
    @percent = threshold.values[0]
    @result = 0
  end

  def discount(item, i_qty)
    if(i_qty > qty)
      @result = (item.price*(percent/'100'.to_d))*(i_qty - qty)
    end
    return result
  end

  def get_proper_suffix
    remainder = qty % 100
    last_digit = qty % 10
    return "th" if (11..13).include? remainder
    return "st" if last_digit == 1
    return "nd" if last_digit == 2
    return "rd" if last_digit == 3
    return "th"
  end

  def line
    text =  "off of every after the"
    output = "|   (#{percent}% #{text} #{qty}#{get_proper_suffix})".ljust(49)+"|"
    return output+("-%.2f" % result).rjust(9)+" |\n"
  end
end

class Coupon
  def register(name, kind)
    case kind.keys.first
      when :amount then AmountCoupon.new name, kind[:amount]
      when :percent then PercentCoupon.new name, kind[:percent]
      else raise "No such kind of coupon!"
    end
  end
end

class NoCoupon
  def line
    ""
  end
end

class AmountCoupon
  attr_reader :amount
  attr_reader :name
  attr_reader :disc

  def initialize(name, amount)
    @amount = amount.to_d
    @name = name
  end

  def discount(total)
    if amount >= total
      @disc = -total
      return total
    else
      @disc = amount
      return amount
    end
  end

  def line
    output = ("| Coupon #{name} - %.2f off" % amount.to_f).ljust(49)+"|" % amount.to_f
    return output+("%.2f" % disc).rjust(9)+" |\n"
  end
end

class PercentCoupon
  attr_reader :percent
  attr_reader :name
  attr_reader :disc

  def initialize(name, percent)
    @name = name
    @percent = percent
    @disc = 0
  end

  def discount(total)
    @disc = (percent/100.0) * total
    return disc
  end

  def line
    output = "| Coupon #{name} - #{percent}% off".ljust(49)+"|"
    return output+("-%.2f" % disc).rjust(9)+" |\n"
  end
end