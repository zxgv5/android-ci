package dev.aaa1115910.bv.tv.screens.main.home

import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.Text
import dev.aaa1115910.biliapi.entity.user.DynamicVideo
import dev.aaa1115910.bv.tv.component.LoadingTip
import dev.aaa1115910.bv.entity.carddata.VideoCardData
import dev.aaa1115910.bv.entity.proxy.ProxyArea
import dev.aaa1115910.bv.tv.R
import dev.aaa1115910.bv.tv.activities.user.FollowActivity
import dev.aaa1115910.bv.tv.activities.video.UpInfoActivity
import dev.aaa1115910.bv.tv.activities.video.VideoInfoActivity
import dev.aaa1115910.bv.tv.component.videocard.SmallVideoCard
import dev.aaa1115910.bv.tv.util.ProvideListBringIntoViewSpec
import dev.aaa1115910.bv.viewmodel.home.DynamicViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.koin.androidx.compose.koinViewModel

@Composable
fun DynamicsScreen(
    modifier: Modifier = Modifier,
    lazyGridState: LazyGridState = rememberLazyGridState(),
    dynamicViewModel: DynamicViewModel = koinViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var currentFocusedIndex by remember { mutableIntStateOf(-1) }

    // 核心修复1：用FocusRequester数组管理每个item焦点（替代Tag+findViewWithTag，兼容TV端Compose）
    val itemFocusRequesters = remember {
        mutableStateListOf<FocusRequester>().apply {
            // 初始化与列表长度匹配的FocusRequester
            repeat(dynamicViewModel.dynamicVideoList.size) { add(FocusRequester()) }
        }
    }

    // 核心修复2：监听列表变化，同步FocusRequester数组长度
    LaunchedEffect(dynamicViewModel.dynamicVideoList.size) {
        if (itemFocusRequesters.size < dynamicViewModel.dynamicVideoList.size) {
            val needAddCount = dynamicViewModel.dynamicVideoList.size - itemFocusRequesters.size
            repeat(needAddCount) { itemFocusRequesters.add(FocusRequester()) }
        } else if (itemFocusRequesters.size > dynamicViewModel.dynamicVideoList.size) {
            itemFocusRequesters.subList(dynamicViewModel.dynamicVideoList.size, itemFocusRequesters.size).clear()
        }
    }

    // 获取当前可见item索引范围（解决“item已添加但未渲染”问题）
    val visibleItemIndices by remember(lazyGridState.layoutInfo) {
        derivedStateOf {
            val layoutInfo = lazyGridState.layoutInfo
            layoutInfo.visibleItemsInfo.map { it.index }.toSet()
        }
    }

    // 加载触发时机（提前6项+防重复加载）
    val shouldLoadMore by remember {
        derivedStateOf {
            dynamicViewModel.dynamicVideoList.isNotEmpty() &&
                    currentFocusedIndex + 6 > dynamicViewModel.dynamicVideoList.size &&
                    !dynamicViewModel.loadingVideo
        }
    }

    val showTip by remember {
        derivedStateOf { dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex >= 0 }
    }

    // 列表最大有效索引
    val maxValidIndex by remember {
        derivedStateOf { dynamicViewModel.dynamicVideoList.size - 1 }
    }

    val onClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        VideoInfoActivity.actionStart(
            context = context,
            aid = dynamic.aid,
            proxyArea = ProxyArea.checkProxyArea(dynamic.title)
        )
    }

    val onLongClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        UpInfoActivity.actionStart(
            context,
            mid = dynamic.authorId,
            name = dynamic.author,
            face = dynamic.authorFace
        )
    }

    // 加载更多逻辑
    LaunchedEffect(shouldLoadMore) {
        if (shouldLoadMore) {
            scope.launch(Dispatchers.IO) {
                dynamicViewModel.loadMoreVideo()
            }
        }
    }

    if (dynamicViewModel.isLogin) {
        val padding = dimensionResource(R.dimen.grid_padding)
        val spacedBy = dimensionResource(R.dimen.grid_spacedBy)

        if (showTip) {
            Text(
                modifier = Modifier.fillMaxWidth().offset(x = (-20).dp, y = (-8).dp),
                text = stringResource(R.string.entry_follow_screen),
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                fontSize = 12.sp,
                textAlign = TextAlign.End
            )
        }

        ProvideListBringIntoViewSpec {
            LazyVerticalGrid(
                modifier = modifier
                    .fillMaxSize()
                    .onFocusChanged {
                        if (!it.isFocused) {
                            currentFocusedIndex = -1
                        }
                    }
                    // 核心修复3：拦截下键事件（KeyDown+KeyRepeat），用FocusRequester控制焦点流转
                    .onPreviewKeyEvent { event ->
                        // 菜单键原有逻辑保留
                        if (event.type == KeyEventType.KeyUp && event.key == Key.Menu) {
                            context.startActivity(Intent(context, FollowActivity::class.java))
                            return@onPreviewKeyEvent true
                        }

                        // 拦截向下方向键（处理KeyDown和KeyRepeat，覆盖长按连续事件）
                        val isDownKey = event.key == Key.DirectionDown
                        val isEffectiveEvent = event.type == KeyEventType.KeyDown || event.type == KeyEventType.KeyRepeat
                        if (isDownKey && isEffectiveEvent) {
                            val nextIndex = currentFocusedIndex + 1
                            // 校验下一个item是否有效且已渲染
                            val nextItemAvailable = nextIndex <= maxValidIndex && visibleItemIndices.contains(nextIndex)
                            if (nextItemAvailable) {
                                // 下一项可用，请求焦点（替代focusSearch）
                                scope.launch {
                                    itemFocusRequesters[nextIndex].requestFocus()
                                }
                            }
                            // 无论下一项是否可用，都拦截事件（防止系统默认搜索焦点）
                            return@onPreviewKeyEvent true
                        }

                        false
                    },
                columns = GridCells.Fixed(4),
                state = lazyGridState,
                contentPadding = PaddingValues(padding),
                verticalArrangement = Arrangement.spacedBy(spacedBy),
                horizontalArrangement = Arrangement.spacedBy(spacedBy)
            ) {
                itemsIndexed(dynamicViewModel.dynamicVideoList) { index, item ->
                    SmallVideoCard(
                        modifier = Modifier
                            // 核心修复4：为每个item绑定对应的FocusRequester
                            .focusRequester(itemFocusRequesters[index])
                            .onFocusChanged { focusState ->
                                // 焦点变化时更新当前索引
                                if (focusState.isFocused) {
                                    currentFocusedIndex = index
                                }
                            },
                        data = remember(item.aid) {
                            VideoCardData(
                                avid = item.aid,
                                title = item.title,
                                cover = item.cover,
                                play = item.play,
                                danmaku = item.danmaku,
                                upName = item.author,
                                time = item.duration * 1000L,
                                pubTime = item.pubTime,
                                isChargingArc = item.isChargingArc,
                                badgeText = item.chargingArcBadge
                            )
                        },
                        onClick = { onClickVideo(item) },
                        onLongClick = { onLongClickVideo(item) },
                        // 移除原onFocus回调，改用onFocusChanged绑定FocusRequester
                        onFocus = {}
                    )
                }

                // 加载中提示（原有逻辑保留）
                if (dynamicViewModel.loadingVideo) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            LoadingTip()
                        }
                    }
                }

                // 无更多数据提示（原有逻辑保留）
                if (!dynamicViewModel.videoHasMore) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Text(
                            text = "没有更多了捏",
                            color = Color.White
                        )
                    }
                }
            }
        }
    } else {
        // 未登录提示（原有逻辑保留）
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(text = "请先登录")
        }
    }
}
