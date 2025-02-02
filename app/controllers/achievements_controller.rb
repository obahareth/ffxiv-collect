class AchievementsController < ApplicationController
  include Collection
  before_action :verify_character!, only: :index
  before_action :check_achievements!, except: :show
  before_action :set_owned!, on: :items
  before_action :set_ids!, :set_dates!, on: [:type, :items]
  skip_before_action :set_prices!

  def index
    @types = AchievementType.all.with_filters(cookies).order(:order)
    @achievements = @types.each_with_object({}) do |type, h|
      h[type.id] = type.achievements.with_filters(cookies)
    end
  end

  def show
    @achievement = Achievement.find(params[:id])
  end

  def type
    @type = AchievementType.find(params[:id])
    @categories = @type.categories.with_filters(cookies).order(:order)
    @achievements = @categories.each_with_object({}) do |category, h|
      h[category.id] = category.achievements.with_filters(cookies).includes(:item, :title).order(:order, :id)
    end
  end

  def items
    @q = Achievement.where.not(item_id: nil).with_filters(cookies).ransack(params[:q])
    @achievements = @q.result.ordered
    @owned = Redis.current.hgetall(:achievements)
  end

  def search
    @q = Achievement.with_filters(cookies).ransack(params[:q])

    if params[:q].present?
      @achievements = @q.result
    else
      # Default search results to the latest patch
      @achievements = Achievement.where(patch: Achievement.all.maximum(:patch))
    end

    @achievements = @achievements.ordered
  end
end
