class ItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :update, :destroy]
  before_action :set_category, only: [:edit, :update]
  
  def index
    @items =Item.limit(3).where(buyer_id: nil).order(created_at: :desc)
  end

  def new
    @item = Item.new
    @item.images.build
    set_category_parent_array
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to action: "index"
    else
      set_category_parent_array
      render "new"
    end
  end

  def show
  end

  def edit
  end

  def update
    if @item.update(update_params)
      redirect_to item_path(@item.id)
    else
      set_category_parent_array
      render :edit
    end
  end

  def destroy
    if @item.destroy
      redirect_to root_path
    else
      render :show
    end
  end

  def search
    @items = Item.search(params[:keyword])
  end

  require "payjp"
  def confirm
    @item = Item.find(params[:id])
    if current_user.card.present?
      Payjp.api_key = Rails.application.credentials.dig(:payjp, :PAYJP_SECRET_KEY)
      @card = Card.find_by(user_id: current_user.id)
      customer = Payjp::Customer.retrieve(@card.customer_id)
      @default_card = customer.cards.retrieve(@card.card_id)
      @card_number_display = "**** **** **** " + @default_card.last4
      @exp_month_display = @default_card.exp_month.to_s
      @exp_year_display = @default_card.exp_year.to_s.slice(2,3)
    else
    end
  end

  def pay
    @item = Item.find(params[:id])
    if @item.buyer_id.present?
      redirect_to item_path(@item.id), alert: '売り切れています'
    else
      Payjp.api_key = Rails.application.credentials.dig(:payjp, :PAYJP_SECRET_KEY)
      @item.with_lock do
        if current_user.card.present?
          @card = Card.find_by(user_id: current_user.id)
          charge = Payjp::Charge.create(
            amount: @item.price,
            customer: Payjp::Customer.retrieve(@card.customer_id),
            currency: 'jpy'
          )
        else
          Payjp::Charge.create(
            amount: @item.price,
            card: params['payjp-token'],
            currency: 'jpy'
          )
        end
        if @item.update(buyer_id: current_user.id)
          redirect_to root_path
        else
          flash.now[:alert] = '購入に失敗しました'
          render :confirm
        end
      end
    end
  end

  def get_category_children
    @category_children = Category.find_by(name: "#{params[:parent_name]}", ancestry: nil).children
  end

  def get_category_grandchildren
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  private
  def item_params
    params.require(:item).permit(:name, :text, :category_id, :damage_id, :fee_id, :area_id, :send_date_id, :price, :brand, images_attributes: [:image_url]).merge(seller_id: current_user.id)
  end

  def update_params
    params.require(:item).permit(:name, :text, :category_id, :damage_id, :fee_id, :area_id, :send_date_id, :price, :brand, images_attributes: [:image_url, :_destroy, :id]).merge(seller_id: current_user.id)
  end

  def set_item
    @item = Item.find(params[:id])
  end

  def set_category_parent_array
    @category_parent_array = ["---"]
    Category.where(ancestry: nil).each do |parent|
      @category_parent_array << parent.name
    end
  end

  def set_category
    @parents = Category.where(ancestry:nil)
    @selected_grandchild_category = @item.category
    @category_grandchildren_array = [{id: "---", name: "---"}]
    Category.find("#{@selected_grandchild_category.id}").siblings.each do |grandchild|
      grandchildren_hash = {id: "#{grandchild.id}", name: "#{grandchild.name}"}
      @category_grandchildren_array << grandchildren_hash
    end
    @selected_child_category = @selected_grandchild_category.parent
    @category_children_array = [{id: "---", name: "---"}]
    Category.find("#{@selected_child_category.id}").siblings.each do |child|
      children_hash = {id: "#{child.id}", name: "#{child.name}"}
      @category_children_array << children_hash
    end
    @selected_parent_category = @selected_child_category.parent
    @category_parents_array = [{id: "---", name: "---"}]
    Category.find("#{@selected_parent_category.id}").siblings.each do |parent|
      parent_hash = {id: "#{parent.id}", name: "#{parent.name}"}
      @category_parents_array << parent_hash
    end
  end
end
