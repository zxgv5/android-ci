package dev.aaa1115910.bv.viewmodel.home
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import dev.aaa1115910.biliapi.entity.user.DynamicItem
import dev.aaa1115910.biliapi.entity.user.DynamicVideo
import dev.aaa1115910.biliapi.http.entity.AuthFailureException
import dev.aaa1115910.biliapi.repositories.UserRepository
import dev.aaa1115910.bv.BVApp
import dev.aaa1115910.bv.BuildConfig
import dev.aaa1115910.bv.R
import dev.aaa1115910.bv.util.Prefs
import dev.aaa1115910.bv.util.addAllWithMainContext
import dev.aaa1115910.bv.util.toast
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.koin.android.annotation.KoinViewModel
import dev.aaa1115910.bv.repository.UserRepository as BvUserRepository

@KoinViewModel
class DynamicViewModel(
    private val bvUserRepository: BvUserRepository,
    private val userRepository: UserRepository
) : ViewModel() {
    // 核心列表：仅保留动态视频列表（TV端优化核心）
    val dynamicVideoList = mutableStateListOf<DynamicVideo>()
    // mobile端兼容：保留旧列表引用（空实现，不影响TV端）
    val dynamicAllList = mutableStateListOf<DynamicItem>()

    private var currentPage = 0
    // 规范状态：private set 防止多线程乱改
    var loading by mutableStateOf(false)
        private set
    // mobile端兼容：保留旧加载状态（始终为false）
    var loadingAll by mutableStateOf(false)
        private set
    var hasMore by mutableStateOf(true)
        private set
    // mobile端兼容：保留旧"是否有更多"状态（始终为false）
    var allHasMore by mutableStateOf(false)
        private set

    private var historyOffset: String? = null
    private var updateBaseline: String? = null
    // mobile端兼容：保留旧偏移量变量
    private var allHistoryOffset: String? = null
    private var allUpdateBaseline: String? = null

    val isLogin get() = bvUserRepository.isLogin

    // TV端核心加载方法（优化后）
    suspend fun loadMore() {
        if (!loading && hasMore && isLogin) {
            loadData()
        }
    }

    // mobile端兼容：保留旧加载方法（转发到新方法）
    suspend fun loadMoreVideo() = loadMore()
    // mobile端兼容：保留旧全量加载方法（空实现）
    suspend fun loadMoreAll() {}

    private suspend fun loadData() {
        loading = true
        val nextPage = currentPage + 1
        // 最多重试2次，解决单次网络波动
        repeat(2) { retryCount ->
            runCatching {
                val data = userRepository.getDynamicVideos(
                    page = nextPage,
                    offset = historyOffset.orEmpty(),
                    updateBaseline = updateBaseline.orEmpty(),
                    preferApiType = Prefs.apiType
                )
                // 成功加载：更新状态并退出重试
                currentPage = nextPage
                dynamicVideoList.addAllWithMainContext(data.videos)
                historyOffset = data.historyOffset
                updateBaseline = data.updateBaseline
                hasMore = data.hasMore
                return@repeat
            }.onFailure { e ->
                // 最后一次重试失败才提示
                if (retryCount == 1) {
                    withContext(Dispatchers.Main) {
                        when (e) {
                            is AuthFailureException -> {
                                BVApp.context.getString(R.string.exception_auth_failure).toast(BVApp.context)
                                if (!BuildConfig.DEBUG) bvUserRepository.logout()
                            }
                            else -> "加载动态失败: ${e.localizedMessage}".toast(BVApp.context)
                        }
                    }
                } else {
                    delay(800) // 缩短重试间隔
                }
            }
        }
        loading = false
    }

    // TV端核心清空方法（优化后）
    fun clearData() {
        dynamicVideoList.clear()
        currentPage = 0
        loading = false
        hasMore = true
        historyOffset = null
        updateBaseline = null
    }

    // mobile端兼容：保留旧清空方法（转发到新方法）
    fun clearVideoData() = clearData()
    // mobile端兼容：保留旧全量清空方法（空实现）
    fun clearAllData() {}
}
